defmodule Blogpub.Repo.Migrations.AddPublicKeys do
  use Ecto.Migration

  def change do
    create table(:public_keys, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :key_id, :text, null: false
      add :actor_id, references(:actors, type: :uuid)
      add :pem, :text, null: false
    end
  end
end
