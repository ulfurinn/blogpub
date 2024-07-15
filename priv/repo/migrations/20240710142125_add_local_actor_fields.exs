defmodule Blogpub.Repo.Migrations.AddLocalActorFields do
  use Ecto.Migration

  def change do
    alter table(:actors) do
      add :local, :boolean
      add :username, :text
    end
  end
end
