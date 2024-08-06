defmodule Blogpub.Object do
  use Blogpub.Schema
  alias Blogpub.APub

  schema "objects" do
    field :content, :map

    belongs_to :actor, Blogpub.Actor
    belongs_to :reply_to_object, __MODULE__

    timestamps()
  end

  def new(actor, object) do
    object =
      object
      |> Map.put("attributedTo", APub.actor_url(actor))
      |> Map.replace_lazy("id", &Blogpub.rewrite_host/1)

    %Object{
      id: Uniq.UUID.uuid7(),
      actor: actor,
      content: object
    }
  end
end
