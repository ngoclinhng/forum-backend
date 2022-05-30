defmodule YojeeWeb.Resolvers.Forum do
  alias Yojee.Forum
  alias Yojee.ForumBridge
  alias YojeeWeb.Schema.ChangesetErrors
  alias YojeeWeb.Schema.Node
  alias YojeeWeb.Resolvers.Connection

  def get_node(_parent, %{type: :thread, id: id}, _resolution) do
    {:ok, Forum.get_thread(id)}
  end

  def get_node(_parent, %{type: :post, id: id}, _resolution) do
    {:ok, Forum.get_post(id)}
  end

  def get_node(_parent, _args, _resolution), do: {:ok, nil}

  def most_popular_threads(_, %{count: count}, _) do
    {:ok, Forum.list_most_popular_threads(count)}
  end

  def threads(_, args, _) do
    Forum.threads_query()
    |> Connection.from_query(&Yojee.Repo.all/1, args, id: :desc)
  end

  def posts(_, args, %{source: thread}) do
    Forum.posts_query(thread)
    |> Connection.from_query(&Yojee.Repo.all/1, args, id: :desc)
  end

  def create_thread(_, args, _) do
    case ForumBridge.create_thread(args) do
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

  def create_post(_, %{thread_id: thread_id} = args, _) do
    # We have to convert the global thread_id into internal id first.
    case Node.from_global_id(thread_id) do
      {:ok, %{type: :thread, id: id}} ->
        create_post(%{args | thread_id: id })

      _ ->
        {:error, "Invalid thread id"}
    end
  end

  # Helpers

  def create_post(args) do
    case ForumBridge.create_post(args) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not create post",
          details: ChangesetErrors.error_details(changeset)
        }

      {:ok, post} ->
        {:ok, %{post: post}}
    end
  end
end
