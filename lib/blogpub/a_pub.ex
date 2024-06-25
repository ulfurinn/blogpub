defmodule Blogpub.APub do
  alias Blogpub.APub.Actor
  alias Blogpub.APub.PublicKey

  def actor(qname) do
    %Actor{
      id: Blogpub.host() <> "/" <> qname,
      preferred_username: qname,
      inbox: Blogpub.host() <> "/inbox",
      outbox: Blogpub.host() <> "/outbox",
      public_key: public_key(qname)
    }
  end

  def public_key(qname) do
    feed = Blogpub.feed(qname)

    %PublicKey{
      id: Blogpub.host() <> "/" <> qname <> "#main-key",
      owner: Blogpub.host() <> "/" <> qname,
      public_key_pem: Application.get_env(:blogpub, :keys)[feed][:public]
    }
  end
end
