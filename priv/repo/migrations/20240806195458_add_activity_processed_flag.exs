defmodule Blogpub.Repo.Migrations.AddActivityProcessedFlag do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add :processed, :boolean, null: false, default: false
    end
  end
end
