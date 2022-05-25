defmodule Yojee.Forum do
  @moduledoc """
  The Forum context.
  """

  import Ecto.Query, warn: false
  alias Yojee.Repo

  alias Yojee.Forum.{Thread, Post}

  @doc """
  Returns a thread whose id is given by `id`.

  Returns `nil` if no such thread exists.
  """
  def get_thread(id) do
    Thread
    |> Repo.get(id)
  end

  @doc """
  Creates a thread with the given attributes `attrs`.

  Returns `{:ok, %Thread{}}` if success.

  Returns `{:error, changeset}`, otherwise.
  """
  def create_thread(attrs) do
    %Thread{}
    |> Thread.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a post with the given attributes `attrs`.

  Returns `{:ok, post` if success.

  Returns `{:error, changeset}`, otherwise.
  """
  def create_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end
end
