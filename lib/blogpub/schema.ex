defmodule Blogpub.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      alias __MODULE__

      @primary_key {:id, Uniq.UUID, version: 7, type: :uuid, autogenerate: false}
      @foreign_key_type Uniq.UUID
      @timestamps_opts [type: :utc_datetime]
    end
  end
end
