defmodule Yojee.Forum.Thread do
  use Ecto.Schema
  import Ecto.Changeset

  schema "threads" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
