defmodule BlogpubWeb.Webfinger.Controller do
  use BlogpubWeb, :controller

  def resource(conn, %{"resource" => url}) do
    case Blogpub.Webfinger.resource(url) do
      %Blogpub.Webfinger.Resource{} = resource ->
        conn |> render(:resource, resource: resource)

      :not_found ->
        conn |> put_status(:not_found) |> put_resp_content_type("text/plain") |> text("")
    end
  end

  def resource(conn, _) do
    conn |> put_status(:bad_request) |> text("")
  end
end
