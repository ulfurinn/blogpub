defmodule Blogpub.Seed do
  import Ecto.Query, only: [from: 2]

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {Task, :start_link, [&__MODULE__.run/0]},
      restart: :temporary
    }
  end

  def run do
    Blogpub.Release.migrate()

    existing_feeds = from(f in Blogpub.Feed, select: f.cname) |> Blogpub.Repo.all()
    feeds_to_create = Blogpub.feed_names() -- existing_feeds

    feeds_to_create
    |> Enum.reduce(Ecto.Multi.new(), fn feed, multi ->
      changeset = Blogpub.Feed.new() |> Blogpub.Feed.changeset(%{cname: feed})

      Ecto.Multi.insert(multi, feed, changeset)
    end)
    |> Blogpub.Repo.transaction()
    |> ok!()
  end

  defp ok!({:ok, _}), do: nil
end
