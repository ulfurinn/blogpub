defmodule Blogpub.Announce do
  use Ecto.Schema

  @primary_key false
  @foreign_key_type Uniq.UUID
  @timestamps_opts [type: :utc_datetime]

  schema "announces" do
    belongs_to :actor, Blogpub.Actor
    belongs_to :object, Blogpub.Object
    timestamps updated_at: false
  end
end
