defmodule BlogpubWeb.APub.Controller do
  alias Blogpub.APub
  use BlogpubWeb, :controller
  require Logger

  def actor(conn, %{"feed" => feed}) do
    if Blogpub.has_feed?(feed) do
      conn
      |> put_resp_content_type("application/activity+json")
      |> render(:actor, actor: APub.actor(feed))
    else
      conn
      |> put_status(:not_found)
      |> put_resp_content_type("text/plain")
      |> text("")
    end
  end

  def actor(conn, _) do
    conn
    |> put_status(:bad_request)
    |> put_resp_content_type("text/plain")
    |> text("")
  end

  def inbox(conn, _params) do
    request = Blogpub.InboxRequest.from_plug_conn!(conn)
    dbg(digest: verify_digest(conn))

    case request |> Blogpub.InboxRequest.verify_signature() |> dbg do
      :ok ->
        conn
        |> put_status(:ok)
        |> put_resp_content_type("text/plain")
        |> text("")

      :missing_signature ->
        conn
        |> put_status(:bad_request)
        |> put_resp_content_type("text/plain")
        |> text("unsigned request")

      :discard ->
        conn
        |> put_status(:ok)
        |> put_resp_content_type("text/plain")
        |> text("")

      :invalid_signature ->
        conn
        |> put_status(:bad_request)
        |> put_resp_content_type("text/plain")
        |> text("invalid signature")

      :missing_key ->
        conn
        |> put_status(:bad_request)
        |> put_resp_content_type("text/plain")
        |> text("public key not available")
    end
  end

  def outbox(conn, %{"feed" => feed}) do
    outbox =
      feed
      |> Blogpub.feed_with_entries()

    conn
    |> put_resp_content_type("application/activity+json")
    |> render(:actor, actor: APub.outbox(outbox))
  end

  defp verify_digest(conn) do
    with {:ok, algo, digest} <- get_digest(conn) do
      verify_digest(conn, algo, digest)
    else
      err -> err
    end
  end

  defp verify_digest(conn, "sha-256", digest) do
    body = BlogpubWeb.CachingReader.body(conn)
    calculated = :crypto.hash(:sha256, body) |> Base.encode64()

    if calculated == digest do
      :ok
    else
      {:digest_mismatch, digest, calculated}
    end
  end

  defp verify_digest(_, algo, _) do
    {:unknown_digest_algorithm, algo}
  end

  defp get_digest(conn) do
    with [digest] <- get_req_header(conn, "digest"),
         [algo, digest] <- String.split(digest, "=", parts: 2) do
      {:ok, String.downcase(algo), digest}
    else
      [] -> :missing_digest
      _ -> :malformed_digest_header
    end
  end
end
