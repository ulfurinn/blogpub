defmodule BlogpubWeb.CachingReader do
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = update_in(conn.private[__MODULE__], &[&1 || "" | body])
    {:ok, body, conn}
  end

  def body(conn), do: IO.iodata_to_binary(conn.private[__MODULE__])
end
