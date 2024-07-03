defmodule Blogpub.HttpSignature do
  alias __MODULE__

  defstruct [
    :key_id,
    :algorithm,
    :headers,
    :data,
    :signature
  ]

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

  def verify(signature, key) do
    %HttpSignature{headers: headers, data: data, signature: given_signature} = signature

    signed_string =
      headers |> Enum.map(fn header -> "#{header}: #{data[header]}" end) |> Enum.join("\n")

    with {:ok, digest} <- digest(signature),
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

  defp get_header(conn, header) do
    case Plug.Conn.get_req_header(conn, header) do
      [value] -> {:ok, value}
      [] -> {:missing_header, header}
      _ -> {:multiple_headers, header}
    end
  end

  defp base64_decode(string) do
    case Base.decode64(string) do
      :error -> :invalid_base64
      ok -> ok
    end
  end

  defp digest(%HttpSignature{algorithm: algorithm}), do: digest(algorithm)
  defp digest("rsa-sha1"), do: {:ok, :sha1}
  defp digest("rsa-sha224"), do: {:ok, :sha224}
  defp digest("rsa-sha256"), do: {:ok, :sha256}
  defp digest("rsa-sha384"), do: {:ok, :sha384}
  defp digest("rsa-sha512"), do: {:ok, :sha512}
  defp digest(_), do: :unsupported_signature_algorithm
end
