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
    |> where([t], t.id == ^id)
    |> with_post_count()
    |> Repo.one
  end

  @doc """
  Returns a post whose id is given by `id`.

  Returns `nil` if no such post exists.
  """
  def get_post(id) do
    Repo.get(Post, id)
  end

  @doc """
  Returns a list of `n` most popular threads, where polularity is based
  on the number of posts: the more posts a thread has the more popular
  it is.
  """
  def list_most_popular_threads(n) when is_integer(n) and n > 0 do
    Thread
    |> with_post_count()
    |> order_by([t, p], desc: count(p.id))
    |> limit(^n)
    |> Repo.all
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
    |> case do
         {:ok, thread} ->
           {:ok, struct!(thread, post_count: 0)}

         {:error, changeset} ->
           {:error, changeset}
       end
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

  # dataloader

  def datasource() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(queryable, _) do
    queryable
  end

  # Helpers

  # thread with post_count
  defp with_post_count(queryable) do
    queryable
    |> join(:left, [t], p in assoc(t, :posts))
    |> group_by([t, p], t.id)
    |> select_merge([t, p], %{post_count: count(p.id)})
  end
end
