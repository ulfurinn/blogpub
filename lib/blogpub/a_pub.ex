defmodule Blogpub.APub do
  alias Blogpub.APub.Actor
  alias Blogpub.APub.PublicKey

  def actor(qname) do
    %Actor{
      id: actor_url(qname),
      preferred_username: qname,
      inbox: inbox_url(qname),
      outbox: outbox_url(qname),
      public_key: public_key(qname),
      endpoints: %{
        sharedInbox: shared_inbox_url()
      }
    }
  end

  def public_key(qname) do
    feed = Blogpub.feed(qname)

    %PublicKey{
      id: actor_url(qname) <> "#main-key",
      owner: actor_url(qname),
      public_key_pem: Application.get_env(:blogpub, :keys)[feed][:public]
    }
  end

  def actor_url(qname), do: Blogpub.host() <> "/feed/" <> qname
  def inbox_url(qname), do: Blogpub.host() <> "/feed/" <> qname <> "/inbox"
  def outbox_url(qname), do: Blogpub.host() <> "/feed/" <> qname <> "/outbox"
  def shared_inbox_url, do: Blogpub.host() <> "/inbox"
end
