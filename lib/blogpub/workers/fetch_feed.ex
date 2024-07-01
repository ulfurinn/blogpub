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
    feed = from(f in Blogpub.Feed, where: f.cname == ^feed) |> Repo.one!()
    url = Blogpub.feeds()[feed.cname]

    case HTTPoison.get(url) do
      {:ok, resp = %HTTPoison.Response{status_code: 200}} ->
        published_urls = published_urls(resp.body)
        known_urls = known_urls(feed)

        (published_urls -- known_urls)
        |> Enum.each(&fetch_item(feed, &1))

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

  defp known_urls(feed) do
    from(e in Blogpub.Entry,
      where: e.feed_id == ^feed.id,
      select: e.source_url
    )
    |> Repo.all()
  end

  defp fetch_item(feed, url) do
    Logger.info("fetching #{url} from feed #{feed.cname}")

    with {:ok, resp = %HTTPoison.Response{status_code: 200}} <-
           HTTPoison.get(url, %{"accept" => "application/activity+json"}),
         {:ok, object} <- Jason.decode(resp.body) do
      entry = Blogpub.Entry.from_object(feed, url, object)
      Repo.insert(entry)
    else
      error ->
        Logger.error("Unexpected: #{inspect(error)}")
    end

    :ok
  end
end
