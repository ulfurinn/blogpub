defmodule Blogpub.Entry do
  use Ecto.Schema
  alias __MODULE__

  @primary_key {:id, Uniq.UUID, version: 7, autogenerate: false}
  @foreign_key_type Uniq.UUID
  @timestamps_opts [type: :utc_datetime]
  schema "entries" do
    field :source_url, :string
    field :apub_data, :map

    belongs_to :feed, Blogpub.Feed

    timestamps()
  end

  def from_object(feed, url, object) do
    %Entry{
      id: Uniq.UUID.uuid7(),
      source_url: url,
      apub_data: object,
      feed: feed
    }
  end
end
