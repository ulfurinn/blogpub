defmodule Blogpub.Repo.Migrations.AddInboxToActors do
  use Ecto.Migration

  def change do
    alter table(:actors) do
      add :inbox_id, references(:collections, type: :uuid)
    end
  end
end
