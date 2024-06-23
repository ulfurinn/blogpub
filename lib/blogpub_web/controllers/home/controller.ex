defmodule BlogpubWeb.Home.Controller do
  use BlogpubWeb, :controller

  def index(conn, _) do
    conn |> text("blogpub/1.0")
  end
end
