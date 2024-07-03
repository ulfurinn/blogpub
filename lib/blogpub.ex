defmodule Blogpub do
  @moduledoc """
  Blogpub keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  import Ecto.Query
  alias Blogpub.Feed
  alias Blogpub.Repo

  def name(feed), do: Application.get_env(:blogpub, :name) <> " · " <> feed
  def description(feed), do: Application.get_env(:blogpub, :feeds)[feed].description
  def host, do: Application.get_env(:blogpub, :host)
  def domain, do: Application.get_env(:blogpub, :domain)
  def website, do: Application.get_env(:blogpub, :website)
  def pub_domain, do: Application.get_env(:blogpub, :pub_domain) || domain()
  def feeds, do: Application.get_env(:blogpub, :feeds)
  def feed_names, do: feeds() |> Map.keys()

  def own_domain?(domain), do: domain == domain() || domain == pub_domain()

  def has_feed?(feed) do
    feed in feed_names()
  end

  def feed_with_entries(feed) do
    from(f in Feed,
      join: e in assoc(f, :entries),
      where: f.cname == ^feed,
      preload: [entries: e],
      order_by: [desc: e.apub_data["published"]]
    )
    |> Repo.one()
  end
end
