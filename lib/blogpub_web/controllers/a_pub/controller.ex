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

  def inbox(conn, params) do
    request = Blogpub.InboxRequest.from_plug_conn!(conn)

    with :ok <- request |> Blogpub.InboxRequest.verify_signature(),
         :ok <- request |> Blogpub.InboxRequest.handle(params["feed"]) do
      conn
      |> put_status(:ok)
      |> put_resp_content_type("text/plain")
      |> text("")
    else
      :missing_signature ->
        Logger.error("no signature header")

        conn
        |> put_status(:bad_request)
        |> put_resp_content_type("text/plain")
        |> text("unsigned request")

      :invalid_signature ->
        Logger.error("invalid signature")

        conn
        |> put_status(:bad_request)
        |> put_resp_content_type("text/plain")
        |> text("invalid signature")

      :missing_key ->
        Logger.error("could not retrieve public key")

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
    |> render(:outbox, outbox: APub.outbox(outbox))
  end
end
