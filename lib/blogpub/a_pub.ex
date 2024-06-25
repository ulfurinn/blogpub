defmodule Blogpub.APub do
  alias Blogpub.APub.Actor
  alias Blogpub.APub.PublicKey

  def actor(qname) do
    %Actor{
      id: actor_url(qname),
      preferred_username: qname,
      inbox: Blogpub.host() <> "/inbox",
      outbox: Blogpub.host() <> "/outbox",
      public_key: public_key(qname)
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
end
