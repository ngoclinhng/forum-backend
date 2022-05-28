defmodule YojeeWeb.Resolvers.Cursor do
  @moduledoc """
  Custom cursor for Relay-style pagination.
  """

  @prefix "keyfuck"
  @pad_length 2
  @pad_bits @pad_length * 8

  @doc """
  Creates the cursor string from the given struct and key.

  ## Examples

      iex> Cursor.from_key(%{id: 10}, :id)
      "sdVrZXlmdWNrMTA="
  """
  def from_key(%{} = map, key) when is_atom(key) do
    {:ok, encoded_value} =
      Map.fetch!(map, key)
      |> Jason.encode

    padding = padding_from(encoded_value)
    Base.encode64(padding <> @prefix <> encoded_value)
  end

  @doc """
  Retrieves the key from the given cursor string.

  ## Examples

      iex> Cursor.to_key("sdVrZXlmdWNrMTA=")
      {:ok, 10}
      iex> Cursor.to_key("invalid")
      {:error, :invalid_cursor}
  """
  def to_key(encoded_cursor) when is_binary(encoded_cursor) do
    with {:ok, cursor} <- Base.decode64(encoded_cursor),
         <<_::size(@pad_bits)>> <> @prefix <> encoded_value <- cursor,
         {:ok, value} <- Jason.decode(encoded_value) do
      {:ok, value}
    else
      _ -> {:error, :invalid_cursor}
    end
  end

  # Builds a varied but deterministic padding string from the input.
  defp padding_from(string) do
    :crypto.hash(:sha, string)
    |> Kernel.binary_part(0, @pad_length)
  end
end
