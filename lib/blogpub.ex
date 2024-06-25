defmodule Blogpub do
  @moduledoc """
  Blogpub keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def host, do: Application.get_env(:blogpub, :host)
  def domain, do: Application.get_env(:blogpub, :domain)
  def pub_domain, do: Application.get_env(:blogpub, :pub_domain) || domain()
  def username, do: Application.get_env(:blogpub, :username)
  def feeds, do: Application.get_env(:blogpub, :feeds)
  def feed_names, do: feeds() |> Map.keys()

  def feed(qname) do
    [_, feed] = String.split(qname, "-", parts: 2)
    feed
  end

  def own_domain?(domain), do: domain == domain() || domain == pub_domain()

  def has_user?(qname) do
    case String.split(qname, "-", parts: 2) do
      [name, feed] -> name == username() && feed in feed_names()
      _ -> false
    end
  end
end
