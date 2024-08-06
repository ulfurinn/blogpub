defmodule Blogpub.Activity do
  use Blogpub.Schema
  import Ecto.Changeset

  schema "activities" do
    field :processed, :boolean, default: false
    field :content, :map
    belongs_to :collection, Blogpub.Collection
    timestamps()
  end

  def processed(activity) do
    change(activity, processed: true)
  end
end
