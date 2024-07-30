defmodule BlogpubWeb.APub.Controller do
  use BlogpubWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias Blogpub.Object
  alias Blogpub.APub
  alias Blogpub.Actor
  require Logger

  def actor(conn, %{"feed" => feed}) do
    case Blogpub.local_actor_by_username(feed, Blogpub.Repo) do
      %Actor{object: object} ->
        conn
        |> put_resp_content_type("application/activity+json")
        |> render(:actor, actor: object)

      nil ->
        not_found(conn)
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
    Logger.info(conn.host)
    Logger.info(request.raw_body)

    with :ok <- check_processing(request),
         :ok <- request |> Blogpub.InboxRequest.verify_signature(),
         :ok <- request |> Blogpub.handle_request(params["feed"]) do
      conn
      |> put_status(:ok)
      |> put_resp_content_type("text/plain")
      |> text("")
    else
      :ignore ->
        Logger.error("ignoring request")

        conn
        |> put_status(:ok)
        |> put_resp_content_type("text/plain")
        |> text("")

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
        |> put_status(:ok)
        |> put_resp_content_type("text/plain")
        |> text("")
    end
  end

  def outbox(conn, %{"feed" => feed}) do
    outbox = feed |> Blogpub.feed_with_entries(Blogpub.Repo)

    conn
    |> put_resp_content_type("application/activity+json")
    |> render(:outbox, outbox: APub.outbox(outbox))
  end

  def following(conn, params = %{"feed" => feed}) do
    case Blogpub.local_actor_by_username(feed, Blogpub.Repo) do
      actor = %Actor{} ->
        conn
        |> put_resp_content_type("application/activity+json")
        |> render(:collection, collection: APub.following(actor, page(params)))

      nil ->
        not_found(conn)
    end
  end

  def followers(conn, params = %{"feed" => feed}) do
    case Blogpub.local_actor_by_username(feed, Blogpub.Repo) do
      actor = %Actor{} ->
        conn
        |> put_resp_content_type("application/activity+json")
        |> render(:collection, collection: APub.followers(actor, page(params)))

      nil ->
        not_found(conn)
    end
  end

  def object(conn, _params) do
    uri = %URI{scheme: "https", host: Blogpub.domain(), path: conn.request_path}

    object =
      from(o in Blogpub.Object, where: o.content["id"] == ^URI.to_string(uri), preload: :actor)
      |> Blogpub.Repo.one()

    case object do
      %Object{} ->
        addressing = [
          to: [APub.followers_url(object.actor)],
          cc: [APub.public()]
        ]

        conn
        |> put_resp_content_type("application/activity+json")
        |> render(:object, object: APub.object(object, addressing: addressing))

      nil ->
        conn
        |> not_found()
    end
  end

  defp check_processing(%Blogpub.InboxRequest{
         body: %{"type" => "Delete", "actor" => actor, "object" => actor}
       }),
       do: :ignore

  defp check_processing(_), do: :ok

  defp page(%{"page" => page}) do
    case Integer.parse(page) do
      {page, ""} -> page
      _ -> nil
    end
  end

  defp page(_), do: nil

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_resp_content_type("text/plain")
    |> text("")
  end
end
