defmodule Blogpub.Repo.Migrations.DropFeedsAndEntries do
  use Ecto.Migration

  def change do
    drop table(:entries)
    drop table(:feeds)
  end
end
