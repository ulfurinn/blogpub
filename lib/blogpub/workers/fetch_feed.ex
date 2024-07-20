defmodule Blogpub.Workers.FetchFeed do
  use Oban.Worker
  import Ecto.Query, only: [from: 2]
  import SweetXml
  alias Blogpub.Repo
  alias Oban.Job
  require Logger

  def run(feed) do
    %{feed: feed}
    |> new()
    |> Oban.insert!()
  end

  def perform(%Job{args: %{"feed" => feed}}) do
    Logger.info("fetching feed #{feed}")

    actor = from(a in Blogpub.Actor, where: a.username == ^feed) |> Repo.one!()
    url = Blogpub.feeds()[actor.username].atom

    case HTTPoison.get(url) do
      {:ok, resp = %HTTPoison.Response{status_code: 200}} ->
        published_urls = published_urls(resp.body)
        known_urls = known_urls(actor)

        (published_urls -- known_urls)
        |> Enum.each(&fetch_item(actor, &1))

        :ok

      _ ->
        {:cancel, :http_error}
    end
  end

  defp published_urls(doc) do
    doc
    |> SweetXml.parse()
    |> SweetXml.xpath(~x"/rss/channel/item"l, url: ~x"./link/text()")
    |> Enum.map(&List.to_string(&1.url))
  end

  defp known_urls(actor) do
    from(o in Blogpub.Object,
      where: o.actor_id == ^actor.id,
      select: o.content["id"]
    )
    |> Repo.all()
  end

  defp fetch_item(actor, url) do
    Logger.info("fetching #{url} from actor #{actor.username}")

    with {:ok, resp = %HTTPoison.Response{status_code: 200}} <-
           HTTPoison.get(url, %{"accept" => "application/x-blogpub-partial"}),
         {:ok, object} <- Jason.decode(resp.body) do
      object = Blogpub.Object.from_partial_object(actor, object)
      Repo.insert(object)
    else
      error ->
        Logger.error("Unexpected: #{inspect(error)}")
    end

    :ok
  end
end
