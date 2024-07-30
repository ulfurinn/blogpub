defmodule Blogpub.APub do
  use BlogpubWeb, :verified_routes

  alias Blogpub.APub.Activity
  alias Blogpub.APub.Actor
  alias Blogpub.APub.OrderedCollection
  alias Blogpub.APub.OrderedCollectionPage
  alias Blogpub.APub.Image
  alias Blogpub.APub.Object
  alias Blogpub.APub.Outbox
  alias Blogpub.APub.PublicKey

  @public "https://www.w3.org/ns/activitystreams#Public"

  def public, do: @public

  def embedded(activity = %{"@context" => _}), do: Map.delete(activity, "@context")
  def embedded(activity = %_struct{"@context": _}), do: %{activity | "@context": nil}

  def actor(actor) do
    %Actor{
      id: actor_url(actor),
      preferredUsername: actor,
      name: Blogpub.name(actor),
      summary: Blogpub.description(actor),
      url: Blogpub.website(),
      icon: %Image{mediaType: "image/jpeg", url: Blogpub.gravatar_url()},
      inbox: inbox_url(actor),
      outbox: outbox_url(actor),
      following: following_url(actor),
      followers: followers_url(actor),
      publicKey: public_key(actor),
      endpoints: %{
        sharedInbox: shared_inbox_url()
      }
    }
  end

  def public_key(actor) do
    %PublicKey{
      id: key_url(actor),
      owner: actor_url(actor),
      publicKeyPem: Application.get_env(:blogpub, :feeds)[actor].keys.public
    }
  end

  def outbox(actor) do
    addressing = [
      to: [followers_url(actor)],
      cc: [@public]
    ]

    %Outbox{
      id: outbox_url(actor),
      summary: actor.username,
      totalItems: length(actor.objects),
      orderedItems:
        Enum.map(actor.objects, &embedded(object_to_create_activity(&1, addressing: addressing)))
    }
  end

  def following(actor, nil) do
    %OrderedCollection{
      id: following_url(actor),
      totalItems: 0
    }
  end

  def following(actor, page) do
    %OrderedCollectionPage{
      id: following_url(actor, page),
      totalItems: 0,
      partOf: following_url(actor),
      orderedItems: []
    }
  end

  def followers(actor, nil) do
    count = Blogpub.followers_count(actor)

    %OrderedCollection{
      id: followers_url(actor),
      totalItems: count,
      first: if(count > 0, do: followers_url(actor, 1), else: nil)
    }
  end

  @followers_page_size 10

  def followers(actor, page) do
    count = Blogpub.followers_count(actor)

    items =
      Blogpub.followers(actor, @followers_page_size, (page - 1) * @followers_page_size)
      |> Enum.map(& &1.url)

    last_item_number = (page - 1) * @followers_page_size + length(items)

    %OrderedCollectionPage{
      id: followers_url(actor, page),
      totalItems: count,
      partOf: followers_url(actor),
      prev: if(page > 1, do: followers_url(actor, page - 1), else: nil),
      next: if(count > last_item_number, do: followers_url(actor, page + 1), else: nil),
      orderedItems: items
    }
  end

  def object_to_create_activity(object, opts) do
    addressing = Keyword.fetch!(opts, :addressing)

    %Activity{
      type: "Create",
      id: object.content["id"] <> "#create",
      actor: object.content["attributedTo"],
      to: Keyword.fetch!(addressing, :to),
      cc: Keyword.fetch!(addressing, :cc),
      object: %Object{
        id: object.content["id"],
        type: object.content["type"],
        name: object.content["name"],
        summary: object.content["summary"],
        content: object.content["content"],
        url: object.content["url"],
        published: object.content["published"],
        attributedTo: object.content["attributedTo"],
        to: Keyword.fetch!(addressing, :to),
        cc: Keyword.fetch!(addressing, :cc)
      }
    }
  end

  def apub_url(path), do: Blogpub.host() <> path

  def actor_url(%Blogpub.Actor{username: username}), do: actor_url(username)
  def actor_url(username) when is_binary(username), do: apub_url(~p"/#{username}")

  def key_url(actor), do: actor_url(actor) <> "#main-key"

  def inbox_url(%Blogpub.Actor{username: username}), do: inbox_url(username)
  def inbox_url(username) when is_binary(username), do: apub_url(~p"/#{username}/inbox")

  def outbox_url(%Blogpub.Actor{username: username}), do: outbox_url(username)
  def outbox_url(username) when is_binary(username), do: apub_url(~p"/#{username}/outbox")

  def following_url(actor, page \\ nil)
  def following_url(%Blogpub.Actor{username: username}, page), do: following_url(username, page)

  def following_url(username, nil) when is_binary(username),
    do: apub_url(~p"/#{username}/following")

  def following_url(username, page) when is_binary(username),
    do: apub_url(~p"/#{username}/following?page=#{page}")

  def followers_url(actor, page \\ nil)
  def followers_url(%Blogpub.Actor{username: username}, page), do: followers_url(username, page)

  def followers_url(username, nil) when is_binary(username),
    do: apub_url(~p"/#{username}/followers")

  def followers_url(username, page) when is_binary(username),
    do: apub_url(~p"/#{username}/followers?page=#{page}")

  def shared_inbox_url, do: apub_url(~p"/inbox")
end
