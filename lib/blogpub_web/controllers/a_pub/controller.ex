defmodule BlogpubWeb.APub.Controller do
  use BlogpubWeb, :controller

  def actor(conn, %{"feed" => feed}) do
    if Blogpub.has_feed?(feed) do
      conn
      |> put_resp_content_type("application/activity+json")
      |> render(:actor, actor: Blogpub.APub.actor(feed))
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
end
