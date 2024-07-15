defmodule Blogpub.Repo.Migrations.AddObjects do
  use Ecto.Migration

  def change do
    create table(:objects, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :object_id, :text
      add :actor_id, references(:actors, type: :uuid)
      add :content, :jsonb
      timestamps()
    end
  end
end
