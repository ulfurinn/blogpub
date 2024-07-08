defmodule Blogpub.Repo.Migrations.AddIncomingActivities do
  use Ecto.Migration

  def change do
    create table(:collections, primary_key: false) do
      add :id, :uuid, primary_key: true
    end

    create table(:activities, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :content, :jsonb

      add :collection_id, references(:collections, type: :uuid)

      timestamps()
    end

    alter table(:feeds) do
      add :inbox_id, references(:collections, type: :uuid)
    end
  end
end
