defmodule Blogpub.Collection do
  use Blogpub.Schema

  schema "collections" do
    has_many :activities, Blogpub.Activity
  end
end
