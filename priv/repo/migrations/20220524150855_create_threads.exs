defmodule Yojee.Repo.Migrations.CreateThreads do
  use Ecto.Migration

  def change do
    create table(:threads) do
      add :title, :string, null: false

      timestamps()
    end
  end
end
