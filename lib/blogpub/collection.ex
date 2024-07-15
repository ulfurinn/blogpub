defmodule Blogpub.Collection do
  use Blogpub.Schema

  schema "collections" do
    has_many :activities, Blogpub.Activity
    has_one :actor, Blogpub.Actor, foreign_key: :inbox_id
  end
end
