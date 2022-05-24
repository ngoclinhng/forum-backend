defmodule YojeeWeb.Resolvers.Forum do
  alias Yojee.Forum

  def thread(_, %{id: id}, _) do
    {:ok, Forum.get_thread(id)}
  end
end
