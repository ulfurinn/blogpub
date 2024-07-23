defmodule Blogpub.Migrate do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_) do
    Blogpub.Release.migrate()
    :ignore
  end
end
