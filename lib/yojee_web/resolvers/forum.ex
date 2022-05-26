defmodule YojeeWeb.Resolvers.Forum do
  alias Yojee.Forum
  alias YojeeWeb.Schema.ChangesetErrors

  def thread(_, %{id: id}, _) do
    {:ok, Forum.get_thread(id)}
  end

  def most_popular_threads(_, %{count: count}, _) do
    {:ok, Forum.list_most_popular_threads(count)}
  end

  def create_thread(_, args, _) do
    case Forum.create_thread(args) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not create thread",
          details: ChangesetErrors.error_details(changeset)
        }

      {:ok, thread} ->
        {:ok, %{thread: thread}}
    end
  end

  def create_post(_, args, _) do
    case Forum.create_post(args) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not create post",
          details: ChangesetErrors.error_details(changeset)
        }

      {:ok, post} ->
        {:ok, post}
    end
  end
end
