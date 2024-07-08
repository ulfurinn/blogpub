defmodule Blogpub.InboxRequest do
  import Ecto.Query
  import Plug.Conn, only: [get_req_header: 2]
  alias __MODULE__
  alias Blogpub.Collection
  alias Blogpub.Repo
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

    case Blogpub.APub.fetch_key(signature.key_id) do
      {:ok, key} ->
        Blogpub.HttpSignature.verify(signature, key)

      :missing_key ->
        Logger.warning("could not fetch key #{signature.key_id}")

        if can_discard?(request) do
          :discard
        else
          :missing_key
        end

      err ->
        err
    end
  end

  def handle(request = %InboxRequest{}, feed) do
    inbox =
      if feed do
        q =
          from c in Collection,
            join: f in assoc(c, :feed),
            where: f.cname == ^feed

        Repo.one(q)
      else
        nil
      end

    activity =
      if inbox do
        Ecto.build_assoc(inbox, :activities, id: Uniq.UUID.uuid7(), content: request.body)
      else
        %Blogpub.Activity{id: Uniq.UUID.uuid7(), content: request.body}
      end

    Repo.insert!(activity)
    :ok
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

  defp can_discard?(request) do
    %InboxRequest{body: body} = request
    match?(%{"type" => "Delete", "object" => actor, "actor" => actor}, body)
  end
end
