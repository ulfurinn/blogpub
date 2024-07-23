defmodule Blogpub.Seed do
  import Ecto.Query, only: [from: 2]
  alias Blogpub.Repo

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
    |> create_local_actors()
    |> create_inbox_collections()
    |> Repo.transaction()
    |> ok!()
  end

  defp create_local_actors(multi) do
    existing_actors =
      from(a in Blogpub.Actor, where: a.local, select: {a.username, a})
      |> Repo.all()
      |> Enum.into(%{})

    defined_actors = Blogpub.feed_names()

    defined_actors
    |> Enum.reduce(multi, fn actor_name, multi ->
      base =
        case existing_actors do
          %{^actor_name => actor} -> actor
          _ -> Blogpub.Actor.new()
        end

      changeset =
        base
        |> Blogpub.Actor.changeset(%{
          local: true,
          username: actor_name,
          url: Blogpub.APub.actor_url(actor_name),
          object: Blogpub.APub.actor(actor_name)
        })

      Ecto.Multi.insert_or_update(multi, "actor_" <> actor_name, changeset)
    end)
  end

  defp create_inbox_collections(multi) do
    actors_without_inboxes = from(a in Blogpub.Actor, where: a.local and is_nil(a.inbox_id))

    multi
    |> Ecto.Multi.all(:actors_without_inboxes, actors_without_inboxes)
    |> Ecto.Multi.run(:inboxes, fn repo, %{actors_without_inboxes: actors} ->
      actors
      |> Enum.reduce_while({:ok, []}, fn actor, {:ok, acc} ->
        inbox = Ecto.build_assoc(actor, :inbox, id: Uniq.UUID.uuid7())

        case repo.insert(inbox) do
          {:ok, inbox} -> {:cont, {:ok, [{actor.id, inbox} | acc]}}
          error -> {:halt, error}
        end
      end)
    end)
    |> Ecto.Multi.run(:inbox_assoc, fn repo, %{inboxes: inboxes} ->
      inboxes
      |> Enum.each(fn {actor_id, inbox} ->
        q = from a in Blogpub.Actor, where: a.id == ^actor_id
        repo.update_all(q, set: [inbox_id: inbox.id])
      end)

      {:ok, nil}
    end)
  end

  defp ok!({:ok, _}), do: nil
end
