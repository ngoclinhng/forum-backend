defmodule YojeeWeb.Resolvers.Forum do
  alias Yojee.Forum
  alias YojeeWeb.Schema.ChangesetErrors

  def thread(_, %{id: id}, _) do
    {:ok, Forum.get_thread(id)}
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
        {:ok, thread}
    end
  end
end
