defmodule BlogpubWeb.ApiKeyAuth do
  import Plug.Conn
  @behaviour Plug

  def init(_) do
    %{api_key: Blogpub.api_key()}
  end

  def call(conn, %{api_key: nil}) do
    conn
  end

  def call(conn, %{api_key: key}) do
    case get_req_header(conn, "x-blogpub-api-key") do
      [^key] -> conn
      _ -> conn |> put_status(401) |> halt()
    end
  end
end
