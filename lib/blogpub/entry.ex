defmodule Blogpub.Entry do
  use Blogpub.Schema

  schema "entries" do
    field :source_url, :string
    field :apub_data, :map

    belongs_to :feed, Blogpub.Feed

    timestamps()
  end

  def from_object(feed, url, object) do
    attrs = %{
      source_url: url,
      apub_data: object,
      feed_id: feed.id
    }

    %Entry{id: Uniq.UUID.uuid7()}
    |> cast(attrs, [:source_url, :apub_data, :feed_id])
  end
end
