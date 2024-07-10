defmodule Blogpub do
  @moduledoc """
  Blogpub keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  import Ecto.Query
  alias Blogpub.HttpSignature
  alias Blogpub.PublicKey
  alias Blogpub.Activity
  alias Blogpub.Collection
  alias Blogpub.Entry
  alias Blogpub.Feed
  alias Blogpub.InboxRequest
  alias Blogpub.Repo
  require Logger

  def api_key, do: Application.get_env(:blogpub, :api_key)

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

  def key(url) do
    key = get_stored_key(url) || fetch_and_store_key(url)

    case key do
      %PublicKey{pem: pem} ->
        {:ok, HttpSignature.decode_pem(pem)}

      err ->
        Logger.error("failed to retrieve public key #{url}: #{inspect(err)}")
        nil
    end
  end

  defp get_stored_key(url) do
    q =
      from k in PublicKey,
        where: k.key_id == ^url

    Repo.one(q)
  end

  defp fetch_and_store_key(url) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, accept: "application/activity+json"),
         {:ok, object} <- Jason.decode(body) do
      store_key(object)
    else
      err -> err
    end
  end

  defp store_key(%{"type" => "Person"} = actor) do
    actor = actor |> store_actor()
    actor.public_key
  end

  def actor(url) do
    get_stored_actor(url) || fetch_and_store_actor(url)
  end

  defp get_stored_actor(url) do
    q =
      from a in Blogpub.Actor,
        where: a.url == ^url,
        preload: :public_key

    Repo.one(q)
  end

  defp fetch_and_store_actor(url) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, accept: "application/activity+json"),
         {:ok, object} <- Jason.decode(body) do
      store_actor(object)
    else
      err -> err
    end
  end

  defp store_actor(object) do
    with actor_entity = %Blogpub.Actor{id: Uniq.UUID.uuid7(), url: object["id"], object: object},
         {:ok, actor} <- Repo.insert(actor_entity),
         %{"publicKey" => %{"id" => id, "publicKeyPem" => pem}} <- object,
         key_entity =
           Ecto.build_assoc(actor, :public_key, id: Uniq.UUID.uuid7(), key_id: id, pem: pem),
         {:ok, key} <- Repo.insert(key_entity) do
      %Blogpub.Actor{actor | public_key: key}
    else
      err -> err
    end
  end

  def handle_request(request = %InboxRequest{}, feed) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:activity, build_activity(request, inbox_collection(feed)))
    |> Ecto.Multi.run(:result, fn repo, %{activity: activity} ->
      execute_activity(activity, repo)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} -> :ok
      err -> err
    end
  end

  defp inbox_collection(feed) do
    if feed do
      q =
        from c in Collection,
          join: f in assoc(c, :feed),
          where: f.cname == ^feed

      Repo.one(q)
    else
      nil
    end
  end

  defp build_activity(request, inbox)

  defp build_activity(request, nil),
    do: %Blogpub.Activity{id: Uniq.UUID.uuid7(), content: request.body}

  defp build_activity(request, inbox),
    do: Ecto.build_assoc(inbox, :activities, id: Uniq.UUID.uuid7(), content: request.body)

  defp execute_activity(activity, repo) do
    {:ok, nil}
  end
end
