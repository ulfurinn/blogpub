defmodule Blogpub.APub do
  alias Blogpub.APub.Activity
  alias Blogpub.APub.Actor
  alias Blogpub.APub.Image
  alias Blogpub.APub.Object
  alias Blogpub.APub.Outbox
  alias Blogpub.APub.PublicKey
  alias Blogpub.Feed

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

  def outbox(feed) do
    %Outbox{
      id: outbox_url(feed),
      summary: feed.cname,
      totalItems: length(feed.entries),
      orderedItems: Enum.map(feed.entries, &entry_to_create_activity(feed, &1))
    }
  end

  def entry_to_create_activity(feed, entry) do
    %Activity{
      type: "Create",
      id: entry_id_url(feed, entry) <> "/create",
      actor: actor_url(feed),
      object: %Object{
        id: entry.source_url,
        type: entry.apub_data["type"],
        name: entry.apub_data["name"],
        summary: entry.apub_data["summary"],
        content: entry.apub_data["content"],
        url: entry.apub_data["url"],
        published: entry.apub_data["published"],
        attributedTo: actor_url(feed),
        to: @public
      }
    }
  end

  def fetch_key(url) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, accept: "application/activity+json"),
         {:ok, actor} <- Jason.decode(body),
         %{"publicKey" => %{"id" => ^url, "publicKeyPem" => pem}} <- actor,
         [pem] <- :public_key.pem_decode(pem) do
      {:ok, :public_key.pem_entry_decode(pem)}
    else
      {:ok, %HTTPoison.Response{status_code: 410}} -> :missing_key
      err -> err
    end
  end

  def actor_url(%Feed{cname: cname}), do: actor_url(cname)
  def actor_url(feed) when is_binary(feed), do: Blogpub.host() <> "/feed/" <> feed

  def inbox_url(%Feed{cname: cname}), do: inbox_url(cname)
  def inbox_url(feed) when is_binary(feed), do: Blogpub.host() <> "/feed/" <> feed <> "/inbox"

  def outbox_url(%Feed{cname: cname}), do: outbox_url(cname)
  def outbox_url(feed) when is_binary(feed), do: Blogpub.host() <> "/feed/" <> feed <> "/outbox"

  def entry_id_url(feed, entry) do
    Blogpub.host() <> "/feed/" <> feed.cname <> "/entry/" <> entry.id
  end

  def shared_inbox_url, do: Blogpub.host() <> "/inbox"
end
