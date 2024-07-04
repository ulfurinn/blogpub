defmodule BlogpubWeb.ApiKeyAuth do
  import Plug.Conn
  @behaviour Plug

  def init(_) do
    nil
  end

  def call(conn, _) do
    key = Blogpub.api_key()
    check(conn, key)
  end

  defp check(conn, nil), do: conn

  defp check(conn, key) do
    case get_req_header(conn, "x-blogpub-api-key") do
      [^key] -> conn
      _ -> conn |> resp(401, "") |> halt()
    end
  end
end
