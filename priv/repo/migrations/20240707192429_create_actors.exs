defmodule Blogpub.Repo.Migrations.CreateActors do
  use Ecto.Migration

  def change do
    create table(:actors, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :webfinger_account, :text
      add :url, :text
      add :object, :jsonb
    end

    create unique_index(:actors, [:webfinger_account])
    create unique_index(:actors, [:url])

    create table(:followers, primary_key: false) do
      add :feed_id, references(:feeds, type: :uuid)
      add :actor_id, references(:actors, type: :uuid)
    end
  end
end
