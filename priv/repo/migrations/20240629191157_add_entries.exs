defmodule Blogpub.Repo.Migrations.AddEntries do
  use Ecto.Migration

  def change do
    create table(:entries, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :feed_id, references(:feeds, type: :uuid)
      add :source_url, :text, unique: true, null: false

      add :apub_data, :jsonb

      timestamps()
    end
  end
end
