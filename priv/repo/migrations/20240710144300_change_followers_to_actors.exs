defmodule Blogpub.Repo.Migrations.ChangeFollowersToActors do
  use Ecto.Migration

  def change do
    alter table(:followers) do
      add :object_id, references(:actors, type: :uuid)
      remove :feed_id
    end
  end
end
