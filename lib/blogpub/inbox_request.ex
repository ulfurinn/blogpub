defmodule Blogpub.InboxRequest do
  import Plug.Conn, only: [get_req_header: 2]
  alias __MODULE__
  require Logger

  defstruct [
    :raw_body,
    :body,
    :signature,
    :digest
  ]

  def from_plug_conn(conn) do
    with {:ok, digest} <- get_digest_header(conn),
         {:ok, signature} <- get_signature_header(conn),
         {:ok, signature} <- Blogpub.HttpSignature.from_plug_conn(conn, signature) do
      request = %__MODULE__{
        raw_body: BlogpubWeb.CachingReader.body(conn),
        body: conn.body_params,
        signature: signature,
        digest: digest
      }

      {:ok, request}
    else
      err -> err
    end
  end

  def from_plug_conn!(conn) do
    case from_plug_conn(conn) do
      {:ok, request} -> request
      err -> raise "request parse error: #{inspect(err)}"
    end
  end

  def verify_signature(%InboxRequest{signature: nil}), do: :missing_signature

  def verify_signature(request) do
    %InboxRequest{signature: signature} = request

    case Blogpub.key(signature.key_id) do
      {:ok, key} ->
        Blogpub.HttpSignature.verify(signature, key)

      nil ->
        Logger.warning("could not fetch key #{signature.key_id}")
        :missing_key
    end
  end

  defp get_digest_header(conn) do
    case get_req_header(conn, "digest") do
      [] -> {:ok, nil}
      [header] -> {:ok, header}
      _ -> :multiple_digests
    end
  end

  defp get_signature_header(conn) do
    case get_req_header(conn, "signature") do
      [] -> {:ok, nil}
      [header] -> {:ok, header}
      _ -> :multiple_signatures
    end
  end
end
