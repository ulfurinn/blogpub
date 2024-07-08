defmodule Blogpub.Feed do
  use Blogpub.Schema

  schema "feeds" do
    field :cname, :string

    has_many :entries, Blogpub.Entry

    many_to_many :followers, Blogpub.Actor, join_through: "followers"
    belongs_to :inbox, Blogpub.Collection

    timestamps()
  end

  def new do
    %Feed{id: Uniq.UUID.uuid7()}
  end

  def changeset(feed, attrs) do
    feed
    |> cast(attrs, [:cname])
  end
end
