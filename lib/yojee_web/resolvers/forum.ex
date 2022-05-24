defmodule YojeeWeb.Resolvers.Forum do
  alias Yojee.Forum

  def thread(_, %{id: id}, _) do
    {:ok, Forum.get_thread(id)}
  end

  def create_thread(_, args, _) do
    case Forum.create_thread(args) do
      {:error, _changeset} ->
        # TODO: error message should be based on changeset error
        {:error, "Oops!"}

      {:ok, thread} ->
        {:ok, thread}
    end
  end
end
