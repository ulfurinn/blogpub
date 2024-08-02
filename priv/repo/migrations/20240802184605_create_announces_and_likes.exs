defmodule Blogpub.Repo.Migrations.CreateAnnouncesAndLikes do
  use Ecto.Migration

  def change do
    create table(:announces, primary_key: false) do
      add :object_id, references(:objects, type: :uuid, null: false)
      add :actor_id, references(:actors, type: :uuid, null: false)
      timestamps(updated_at: false)
    end

    create table(:likes, primary_key: false) do
      add :object_id, references(:objects, type: :uuid, null: false)
      add :actor_id, references(:actors, type: :uuid, null: false)
      timestamps(updated_at: false)
    end
  end
end
