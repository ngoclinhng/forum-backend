defmodule Yojee.Forum.Post do
  use Ecto.Schema
  import Ecto.Changeset

  #  Ecto.Schema.timestamps (:inserted_at and :updated_at) uses
  # `naive_datetime` by default. This configuration overrides that
  # behaviour by using `utc_datetime` instead.
  @timestamps_opts [type: :utc_datetime]

  schema "posts" do
    field :content, :string
    belongs_to :thread, Yojee.Forum.Thread

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end
