defmodule Blogpub.APub do
  alias Blogpub.APub.Actor
  alias Blogpub.APub.PublicKey

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

  def actor_url(feed), do: Blogpub.host() <> "/feed/" <> feed
  def inbox_url(feed), do: Blogpub.host() <> "/feed/" <> feed <> "/inbox"
  def outbox_url(feed), do: Blogpub.host() <> "/feed/" <> feed <> "/outbox"
  def shared_inbox_url, do: Blogpub.host() <> "/inbox"
end
