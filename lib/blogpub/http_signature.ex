defmodule Blogpub.HttpSignature do
  alias Blogpub.PublicKey
  alias __MODULE__

  defstruct [
    :key_id,
    :algorithm,
    :headers,
    :data,
    :signature
  ]

  def decode_pem(pem) do
    case :public_key.pem_decode(pem) do
      [pem | _] -> :public_key.pem_entry_decode(pem)
      _ -> nil
    end
  end

  def from_plug_conn(_conn, nil) do
    {:ok, nil}
  end

  def from_plug_conn(conn, header) do
    segments = parse_segments(header)

    case get_headers(conn, segments["headers"]) do
      {:ok, headers} ->
        signature = %__MODULE__{
          key_id: segments["keyId"],
          algorithm: String.downcase(segments["algorithm"]),
          headers: segments["headers"] |> String.split(" "),
          data: headers,
          signature: segments["signature"]
        }

        {:ok, signature}

      err ->
        err
    end
  end

  def signed_request(url, body, key_id, private) do
    uri = URI.parse(url)
    body = Jason.encode!(body)

    headers = [
      {"content-type", "application/activity+json"},
      {"digest", digest_header(body)},
      {"date", date_header()},
      {"host", uri.host}
    ]

    signature_fields = [
      {"(request-target)", "post #{uri.path}"}
      | take_headers(headers, ~w/host date digest/)
    ]

    signature_string =
      signature_fields
      |> Enum.map(fn {k, v} -> k <> ": " <> v end)
      |> Enum.join("\n")

    signature = :public_key.sign(signature_string, :sha256, private) |> Base.encode64()

    signature_header =
      [
        {"keyId", key_id},
        {"algorithm", "rsa-sha256"},
        {"headers", Enum.map(signature_fields, &elem(&1, 0)) |> Enum.join(" ")},
        {"signature", signature}
      ]
      |> Enum.map(fn {k, v} -> k <> "=\"" <> v <> "\"" end)
      |> Enum.join(",")

    %HTTPoison.Request{
      method: :post,
      url: url,
      headers: [{"signature", signature_header} | headers],
      body: body,
      options: []
    }
  end

  defp take_headers(headers, names) do
    headers |> Enum.filter(fn {k, _} -> k in names end)
  end

  defp date_header, do: DateTime.utc_now() |> Calendar.strftime("%a, %0d %b %Y %X GMT")

  def verify(signature, %PublicKey{pem: pem}) do
    key = HttpSignature.decode_pem(pem)
    %HttpSignature{headers: headers, data: data, signature: given_signature} = signature

    signed_string =
      headers |> Enum.map(fn header -> "#{header}: #{data[header]}" end) |> Enum.join("\n")

    with {:ok, digest} <- signature_algorithm(signature),
         {:ok, decoded} <- base64_decode(given_signature) do
      do_verify(signed_string, digest, decoded, key)
    else
      err -> err
    end
  end

  defp do_verify(message, digest, signature, key) do
    if :public_key.verify(message, digest, signature, key) do
      :ok
    else
      :invalid_signature
    end
  end

  defp parse_segments(header) do
    header
    |> String.split(",")
    |> Enum.into(%{}, fn segment ->
      [k, v] = String.split(segment, "=", parts: 2)
      v = v |> String.trim_leading("\"") |> String.trim_trailing("\"")
      {k, v}
    end)
  end

  defp get_headers(conn, headers) do
    headers
    |> String.split(" ")
    |> Enum.reduce_while({:ok, %{}}, fn header, {:ok, acc} ->
      case get_header(conn, header) do
        {:ok, value} ->
          acc = Map.put(acc, header, value)
          {:cont, {:ok, acc}}

        err ->
          {:halt, err}
      end
    end)
  end

  defp get_header(conn, "(request-target)") do
    {:ok, "#{String.downcase(conn.method)} #{conn.request_path}"}
  end

  defp get_header(conn, "digest") do
    with [raw_digest] <- Plug.Conn.get_req_header(conn, "digest"),
         [algo, digest] <- String.split(raw_digest, "=", parts: 2),
         {:ok, algo} <- hash_algorithm(String.downcase(algo)),
         :ok <- verify_digest(conn, algo, digest) do
      {:ok, raw_digest}
    else
      [] -> {:missing_header, "digest"}
      err -> err
    end
  end

  defp get_header(conn, header) do
    case Plug.Conn.get_req_header(conn, header) do
      [value] -> {:ok, value}
      [] -> {:missing_header, header}
      _ -> {:multiple_headers, header}
    end
  end

  def digest_header(algo \\ :sha256, body) do
    hash_algorithm_name(algo) <> "=" <> digest(algo, body)
  end

  defp digest(algo, body) do
    :crypto.hash(algo, body) |> Base.encode64()
  end

  defp verify_digest(conn, algo, digest) do
    calculated = digest(algo, BlogpubWeb.CachingReader.body(conn))

    if calculated == digest do
      :ok
    else
      {:digest_mismatch, digest, calculated}
    end
  end

  defp base64_decode(string) do
    case Base.decode64(string) do
      :error -> :invalid_base64
      ok -> ok
    end
  end

  defp hash_algorithm("sha-256"), do: {:ok, :sha256}
  defp hash_algorithm(algo), do: {:unsupported_hash_algorithm, algo}

  defp hash_algorithm_name(:sha256), do: "SHA-256"

  defp signature_algorithm(%HttpSignature{algorithm: algorithm}),
    do: signature_algorithm(algorithm)

  defp signature_algorithm("rsa-sha1"), do: {:ok, :sha1}
  defp signature_algorithm("rsa-sha224"), do: {:ok, :sha224}
  defp signature_algorithm("rsa-sha256"), do: {:ok, :sha256}
  defp signature_algorithm("rsa-sha384"), do: {:ok, :sha384}
  defp signature_algorithm("rsa-sha512"), do: {:ok, :sha512}
  defp signature_algorithm(algo), do: {:unsupported_signature_algorithm, algo}
end
