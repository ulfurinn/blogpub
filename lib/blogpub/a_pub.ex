defmodule Blogpub.APub do
  alias Blogpub.APub.Activity
  alias Blogpub.APub.Actor
  alias Blogpub.APub.Image
  alias Blogpub.APub.Object
  alias Blogpub.APub.Outbox
  alias Blogpub.APub.PublicKey

  @public "https://www.w3.org/ns/activitystreams#Public"

  def actor(feed) do
    %Actor{
      id: actor_url(feed),
      preferredUsername: feed,
      name: Blogpub.name(feed),
      summary: Blogpub.description(feed),
      url: Blogpub.website(),
      icon: %Image{mediaType: "image/jpeg", url: Blogpub.gravatar_url()},
      inbox: inbox_url(feed),
      outbox: outbox_url(feed),
      publicKey: public_key(feed),
      endpoints: %{
        sharedInbox: shared_inbox_url()
      }
    }
  end

  def public_key(feed) do
    %PublicKey{
      id: actor_url(feed) <> "#main-key",
      owner: actor_url(feed),
      publicKeyPem: Application.get_env(:blogpub, :feeds)[feed].keys.public
    }
  end

  def outbox(actor) do
    %Outbox{
      id: outbox_url(actor),
      summary: actor.username,
      totalItems: length(actor.objects),
      orderedItems: Enum.map(actor.objects, &object_to_create_activity(actor, &1))
    }
  end

  def object_to_create_activity(actor, object) do
    %Activity{
      type: "Create",
      id: surrogate_object_url(actor, object, "/create"),
      actor: actor_url(actor),
      object: %Object{
        id: object.object_id,
        type: object.content["type"],
        name: object.content["name"],
        summary: object.content["summary"],
        content: object.content["content"],
        url: object.content["url"],
        published: object.content["published"],
        attributedTo: actor_url(actor),
        to: @public
      }
    }
  end

  def actor_url(%Blogpub.Actor{username: username}), do: actor_url(username)
  def actor_url(username) when is_binary(username), do: Blogpub.host() <> "/feed/" <> username

  def inbox_url(%Blogpub.Actor{username: username}), do: inbox_url(username)

  def inbox_url(username) when is_binary(username),
    do: Blogpub.host() <> "/feed/" <> username <> "/inbox"

  def outbox_url(%Blogpub.Actor{username: username}), do: outbox_url(username)

  def outbox_url(username) when is_binary(username),
    do: Blogpub.host() <> "/feed/" <> username <> "/outbox"

  def surrogate_object_url(actor, object, "") do
    Blogpub.host() <> "/feed/" <> actor.username <> "/entry/" <> object.id
  end

  def surrogate_object_url(actor, object, suffix) do
    Blogpub.host() <> "/feed/" <> actor.username <> "/entry/" <> object.id <> suffix
  end

  def shared_inbox_url, do: Blogpub.host() <> "/inbox"
end
