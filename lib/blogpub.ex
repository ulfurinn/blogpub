defmodule Blogpub do
  @moduledoc """
  Blogpub keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  import Ecto.Query
  alias Blogpub.Entry
  alias Blogpub.Feed
  alias Blogpub.Repo

  def name(feed), do: Application.get_env(:blogpub, :name) <> " · " <> feed
  def description(feed), do: Application.get_env(:blogpub, :feeds)[feed].description
  def host, do: Application.get_env(:blogpub, :host)
  def domain, do: Application.get_env(:blogpub, :domain)
  def website, do: Application.get_env(:blogpub, :website)
  def feeds, do: Application.get_env(:blogpub, :feeds)
  def feed_names, do: feeds() |> Map.keys()

  def gravatar_url do
    email = Application.get_env(:blogpub, :gravatar_email)

    hash =
      :crypto.hash(:sha256, email)
      |> Base.encode16()
      |> String.downcase()

    "https://gravatar.com/avatar/#{hash}.jpg"
  end

  def own_domain?(domain), do: domain == domain()

  def has_feed?(feed) do
    feed in feed_names()
  end

  def feed_with_entries(feed) do
    entries = from(e in Entry, order_by: [desc: e.apub_data["published"]])

    from(f in Feed,
      where: f.cname == ^feed,
      preload: [entries: ^entries]
    )
    |> Repo.one()
  end
end
