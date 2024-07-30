defmodule Blogpub.Workers.PublishActivity do
  use Oban.Worker

  def schedule(actor, activity, url) do
    %{actor: actor.username, activity: activity, url: url}
    |> new()
    |> Oban.insert!()
  end

  def perform(%Oban.Job{args: args}) do
    %{"actor" => username, "activity" => activity, "url" => url} = args

    actor =
      Blogpub.local_actor_by_username(username, Blogpub.Repo)
      |> Blogpub.Repo.preload(:public_key)

    Blogpub.make_request(actor, url, activity) |> dbg
    :ok
  end
end
