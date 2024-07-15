defmodule Blogpub.Actor do
  use Blogpub.Schema

  schema "actors" do
    field :webfinger_account, :string
    field :url, :string
    field :object, :map
    field :local, :boolean
    field :username, :string

    has_one :public_key, Blogpub.PublicKey

    many_to_many :following, Blogpub.Actor,
      join_through: "followers",
      join_keys: [actor_id: :id, object_id: :id],
      on_replace: :delete

    many_to_many :followers, Blogpub.Actor,
      join_through: "followers",
      join_keys: [object_id: :id, actor_id: :id],
      on_replace: :delete

    belongs_to :inbox, Blogpub.Collection
    has_many :objects, Blogpub.Object
  end

  def new do
    %Actor{id: Uniq.UUID.uuid7()}
  end

  def changeset(actor, attrs \\ %{}) do
    actor |> cast(attrs, [:url, :object, :local, :username])
  end

  def follower?(actor, follower) do
    Enum.any?(actor.followers, &(&1.url == follower.url))
  end

  def add_follower(actor, follower) do
    actor
    |> change()
    |> put_assoc(:followers, [follower | actor.followers])
  end

  def remove_follower(actor, follower) do
    actor
    |> change()
    |> put_assoc(:followers, Enum.reject(actor.followers, &(&1.url == follower.url)))
  end
end
