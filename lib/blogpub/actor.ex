defmodule Blogpub.Actor do
  use Blogpub.Schema

  schema "actors" do
    field :webfinger_account, :string
    field :url, :string
    field :object, :map

    has_one :public_key, Blogpub.PublicKey
  end
end
