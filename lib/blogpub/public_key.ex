defmodule Blogpub.PublicKey do
  use Blogpub.Schema

  schema "public_keys" do
    field :key_id, :string
    field :pem, :string
    belongs_to :actor, Blogpub.Actor
  end
end
