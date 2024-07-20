defmodule Blogpub.Object do
  use Blogpub.Schema

  schema "objects" do
    field :content, :map

    belongs_to :actor, Blogpub.Actor

    timestamps()
  end

  def from_partial_object(actor, object) do
    attrs = %{
      content: object,
      actor_id: actor.id
    }

    %Object{id: Uniq.UUID.uuid7()}
    |> cast(attrs, [:actor_id, :content])
  end
end
