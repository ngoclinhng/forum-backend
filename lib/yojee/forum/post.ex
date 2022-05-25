defmodule Yojee.Forum.Post do
  use Ecto.Schema
  import Ecto.Changeset

  #  Ecto.Schema.timestamps (:inserted_at and :updated_at) uses
  # `naive_datetime` by default. This configuration overrides that
  # behaviour by using `utc_datetime` instead.
  @timestamps_opts [type: :utc_datetime]

  # The length of each post must be in the range [min, max].
  @allowed_content_length_range [min: 1, max: 10_000]

  schema "posts" do
    field :content, :string
    belongs_to :thread, Yojee.Forum.Thread

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    required_fields = [:content, :thread_id]
    optional_fields = []

    post
    |> cast(attrs, required_fields ++ optional_fields)
    |> validate_required(required_fields)
    |> validate_content()
    |> assoc_constraint(:thread)
  end

  # Helpers

  defp validate_content(%Ecto.Changeset{valid?: true} = changeset) do
    changeset
    |> update_change(:content, &String.trim/1)
    |> validate_length(:content, @allowed_content_length_range)
  end

  defp validate_content(changeset), do: changeset
end
