defmodule Blogpub.APub do
  alias Blogpub.APub.Activity
  alias Blogpub.APub.Actor
  alias Blogpub.APub.Object
  alias Blogpub.APub.Outbox
  alias Blogpub.APub.PublicKey
  alias Blogpub.Feed

  @public "https://www.w3.org/ns/activitystreams#Public"

  def actor(feed) do
    %Actor{
      id: actor_url(feed),
      preferred_username: feed,
      inbox: inbox_url(feed),
      outbox: outbox_url(feed),
      public_key: public_key(feed),
      endpoints: %{
        sharedInbox: shared_inbox_url()
      }
    }
  end

  def public_key(feed) do
    %PublicKey{
      id: actor_url(feed) <> "#main-key",
      owner: actor_url(feed),
      public_key_pem: Application.get_env(:blogpub, :keys)[feed][:public]
    }
  end

  def outbox(feed) do
    %Outbox{
      id: outbox_url(feed),
      summary: feed.cname,
      total_items: length(feed.entries),
      ordered_items: Enum.map(feed.entries, &entry_to_create_activity(feed, &1))
    }
  end

  def entry_to_create_activity(feed, entry) do
    %Activity{
      type: "Create",
      id: entry_url(feed, entry) <> "/create",
      actor: actor_url(feed),
      object: %Object{
        id: entry_url(feed, entry),
        type: entry.apub_data["type"],
        name: entry.apub_data["name"],
        summary: entry.apub_data["summary"],
        content: entry.apub_data["content"],
        url: entry.apub_data["url"],
        published: entry.apub_data["published"],
        attributed_to: actor_url(feed),
        to: @public
      }
    }
  end

  def actor_url(%Feed{cname: cname}), do: actor_url(cname)
  def actor_url(feed) when is_binary(feed), do: Blogpub.host() <> "/feed/" <> feed

  def inbox_url(%Feed{cname: cname}), do: inbox_url(cname)
  def inbox_url(feed) when is_binary(feed), do: Blogpub.host() <> "/feed/" <> feed <> "/inbox"

  def outbox_url(%Feed{cname: cname}), do: outbox_url(cname)
  def outbox_url(feed) when is_binary(feed), do: Blogpub.host() <> "/feed/" <> feed <> "/outbox"

  def entry_url(feed, entry) do
    Blogpub.host() <> "/feed/" <> feed.cname <> "/entry/" <> entry.id
  end

  def shared_inbox_url, do: Blogpub.host() <> "/inbox"
end
