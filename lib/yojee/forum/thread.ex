defmodule Yojee.Forum.Thread do
  use Ecto.Schema
  import Ecto.Changeset

  #  Ecto.Schema.timestamps (:inserted_at and :updated_at) uses
  # `naive_datetime` by default. This configuration overrides that
  # behaviour by using `utc_datetime` instead.
  @timestamps_opts [type: :utc_datetime]

  # The length of each thread must be in the range [min, max].
  @allowed_title_length_range [min: 3, max: 140]

  schema "threads" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(thread, attrs) do
    required_fields = [:title]
    optional_fields = []

    thread
    |> cast(attrs, required_fields ++ optional_fields)
    |> validate_required(required_fields)
    |> validate_title()
  end

  # Helpers.


  defp validate_title(%Ecto.Changeset{valid?: true} = changeset) do
    changeset
    |> update_change(:title, &String.trim/1)
    |> validate_length(:title, @allowed_title_length_range)
  end

  defp validate_title(changeset), do: changeset
end
