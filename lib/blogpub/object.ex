defmodule Blogpub.Object do
  use Blogpub.Schema

  schema "objects" do
    field :object_id, :string
    field :content, :map

    belongs_to :actor, Blogpub.Actor

    timestamps()
  end

  def from_partial_object(actor, url, object) do
    attrs = %{
      object_id: url,
      content: object,
      actor_id: actor.id
    }

    %Object{id: Uniq.UUID.uuid7()}
    |> cast(attrs, [:actor_id, :object_id, :content])
  end
end
