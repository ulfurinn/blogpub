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

    Ecto.Multi.new()
    |> create_feeds()
    |> create_inbox_collections()
    |> Blogpub.Repo.transaction()
    |> ok!()
  end

  defp create_feeds(multi) do
    existing_feeds = from(f in Blogpub.Feed, select: f.cname) |> Blogpub.Repo.all()
    feeds_to_create = Blogpub.feed_names() -- existing_feeds

    feeds_to_create
    |> Enum.reduce(multi, fn feed, multi ->
      changeset = Blogpub.Feed.new() |> Blogpub.Feed.changeset(%{cname: feed})

      Ecto.Multi.insert(multi, feed, changeset)
    end)
  end

  defp create_inbox_collections(multi) do
    feeds_without_inboxes = from(f in Blogpub.Feed, where: is_nil(f.inbox_id))

    multi
    |> Ecto.Multi.all(:feeds_without_inboxes, feeds_without_inboxes)
    |> Ecto.Multi.run(:inboxes, fn repo, %{feeds_without_inboxes: feeds} ->
      feeds
      |> Enum.reduce_while({:ok, []}, fn feed, {:ok, acc} ->
        inbox = Ecto.build_assoc(feed, :inbox, id: Uniq.UUID.uuid7())

        case repo.insert(inbox) do
          {:ok, inbox} -> {:cont, {:ok, [{feed.id, inbox} | acc]}}
          error -> {:halt, error}
        end
      end)
    end)
    |> Ecto.Multi.run(:inbox_assoc, fn repo, %{inboxes: inboxes} ->
      inboxes
      |> Enum.each(fn {feed_id, inbox} ->
        q = from f in Blogpub.Feed, where: f.id == ^feed_id
        repo.update_all(q, set: [inbox_id: inbox.id])
      end)

      {:ok, nil}
    end)
  end

  defp ok!({:ok, _}), do: nil
end
