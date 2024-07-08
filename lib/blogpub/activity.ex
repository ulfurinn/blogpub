defmodule Blogpub.Activity do
  use Blogpub.Schema

  schema "activities" do
    field :content, :map
    belongs_to :collection, Blogpub.Collection
    timestamps()
  end
end
