defmodule Blogpub.Repo.Migrations.AddFeeds do
  use Ecto.Migration

  def change do
    create table(:feeds, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :cname, :text, null: false, unique: true

      timestamps()
    end
  end
end
