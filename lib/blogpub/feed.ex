defmodule Blogpub.Feed do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  @primary_key {:id, Uniq.UUID, version: 7, autogenerate: false}
  @foreign_key_type Uniq.UUID
  @timestamps_opts [type: :utc_datetime]
  schema "feeds" do
    field :cname, :string

    has_many :entries, Blogpub.Entry

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
