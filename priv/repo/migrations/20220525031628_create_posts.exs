defmodule Yojee.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :content, :text, null: false

      add :thread_id,
        references(:threads, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:posts, [:thread_id])
  end
end
