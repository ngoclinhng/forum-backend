defmodule Yojee.Forum do
  @moduledoc """
  The Forum context.
  """

  import Ecto.Query, warn: false
  alias Yojee.Repo

  alias Yojee.Forum.Thread

  @doc """
  Creates a Thread with the given attributes `attrs`.

  Returns `{:ok, %Thread{}}` if success.

  Returns `{:error, changeset}`, otherwise.
  """
  def create_thread(attrs) do
    %Thread{}
    |> Thread.changeset(attrs)
    |> Repo.insert()
  end
end
