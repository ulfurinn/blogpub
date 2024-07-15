defmodule Blogpub do
  @moduledoc """
  Blogpub keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  import Ecto.Query
  alias Blogpub.APub
  alias Blogpub.Activity
  alias Blogpub.Actor
  alias Blogpub.Collection
  alias Blogpub.HttpSignature
  alias Blogpub.InboxRequest
  alias Blogpub.Object
  alias Blogpub.PublicKey
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

  def feed_with_entries(username, repo) do
    objects = from(o in Object, order_by: [desc: o.content["published"]])

    from(a in Actor,
      where: a.local and a.username == ^username,
      preload: [objects: ^objects]
    )
    |> repo.one()
  end

  def key(url, repo) do
    key = get_stored_key(url, repo) || fetch_and_store_key(url, repo)

    case key do
      %PublicKey{pem: pem} ->
        {:ok, HttpSignature.decode_pem(pem)}

      err ->
        Logger.error("failed to retrieve public key #{url}: #{inspect(err)}")
        nil
    end
  end

  defp get_stored_key(url, repo) do
    q =
      from k in PublicKey,
        where: k.key_id == ^url

    repo.one(q)
  end

  defp fetch_and_store_key(url, repo) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, accept: "application/activity+json"),
         {:ok, object} <- Jason.decode(body) do
      store_key(object, repo)
    else
      err -> err
    end
  end

  defp store_key(%{"type" => "Person"} = actor, repo) do
    actor = actor |> store_actor(repo)
    actor.public_key
  end

  def local_actor_by_username(username, repo) do
    q =
      from a in Actor,
        where: a.local and a.username == ^username

    repo.one(q)
  end

  def local_actor_by_url(url, repo) do
    q =
      from a in Actor,
        where: a.local and a.url == ^url

    repo.one(q)
  end

  def actor(url, repo) do
    get_stored_actor(url, repo) || fetch_and_store_actor(url, repo)
  end

  defp get_stored_actor(url, repo) do
    q =
      from a in Blogpub.Actor,
        where: a.url == ^url,
        preload: :public_key

    repo.one(q)
  end

  defp fetch_and_store_actor(url, repo) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, accept: "application/activity+json"),
         {:ok, object} <- Jason.decode(body) do
      store_actor(object, repo)
    else
      err -> err
    end
  end

  defp store_actor(object, repo) do
    with actor_entity = %Blogpub.Actor{id: Uniq.UUID.uuid7(), url: object["id"], object: object},
         {:ok, actor} <- repo.insert(actor_entity),
         %{"publicKey" => %{"id" => id, "publicKeyPem" => pem}} <- object,
         key_entity =
           Ecto.build_assoc(actor, :public_key, id: Uniq.UUID.uuid7(), key_id: id, pem: pem),
         {:ok, key} <- repo.insert(key_entity) do
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
    |> Blogpub.Repo.transaction()
    |> case do
      {:ok, _} -> :ok
      err -> err
    end
  end

  defp inbox_collection(feed) do
    if feed do
      q =
        from c in Collection,
          join: f in assoc(c, :actor),
          where: f.username == ^feed

      Blogpub.Repo.one(q)
    else
      nil
    end
  end

  defp build_activity(request, inbox)

  defp build_activity(request, nil),
    do: %Blogpub.Activity{id: Uniq.UUID.uuid7(), content: request.body}

  defp build_activity(request, inbox),
    do: Ecto.build_assoc(inbox, :activities, id: Uniq.UUID.uuid7(), content: request.body)

  defp execute_activity(activity, repo)

  defp execute_activity(%Activity{content: content}, repo),
    do: execute_activity(content, repo)

  defp execute_activity(activity = %{"type" => "Follow"}, repo) do
    %{"actor" => actor, "object" => object} = activity
    actor = actor(actor, repo)
    object = local_actor_by_url(object, Blogpub.Repo) |> repo.preload([:public_key, :followers])

    :ok = add_follower(object, actor, repo)

    accept = %APub.Activity{
      id: object.url <> "#accepts/follows/" <> Uniq.UUID.uuid7(),
      type: "Accept",
      actor: object.url,
      object: activity |> APub.Activity.embedded()
    }

    request = signed_request(object, actor, accept)
    {:ok, _} = request |> HTTPoison.request()

    {:ok, nil}
  end

  defp execute_activity(
         %{"type" => "Undo", "actor" => actor, "object" => ref = %{"type" => "Follow"}},
         repo
       ) do
    %{"actor" => ^actor, "object" => object} = ref
    actor = actor(actor, repo)
    object = local_actor_by_url(object, Blogpub.Repo) |> repo.preload([:public_key, :followers])

    :ok = remove_follower(object, actor, repo)
    {:ok, nil}
  end

  defp execute_activity(activity, _) do
    Logger.error("activity type #{activity["type"]} not implemented")
    dbg(activity)
    {:ok, nil}
  end

  defp add_follower(object, actor, repo) do
    if Actor.follower?(object, actor) do
      Logger.warning("repeated follow request from #{actor.url} to #{object.url}")
      :ok
    else
      {:ok, _} = object |> Actor.add_follower(actor) |> repo.update()
      :ok
    end
  end

  defp remove_follower(object, actor, repo) do
    if Actor.follower?(object, actor) do
      {:ok, _} = object |> Actor.remove_follower(actor) |> repo.update()
      :ok
    else
      Logger.warning("undoing a follow from #{actor.url} to #{object.url} that is not there")
      :ok
    end
  end

  defp signed_request(from_actor, to_actor, body) do
    HttpSignature.signed_request(
      to_actor.object["inbox"],
      body,
      APub.key_url(from_actor),
      private_key(from_actor)
    )
  end

  defp private_key(actor),
    do:
      HttpSignature.decode_pem(Application.get_env(:blogpub, :feeds)[actor.username].keys.private)
end
