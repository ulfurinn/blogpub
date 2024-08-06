defmodule Blogpub.Repo.Migrations.AddParentObjectReference do
  use Ecto.Migration

  def change do
    alter table(:objects) do
      add :reply_to_object_id, references(:objects, type: :uuid)
    end
  end
end
