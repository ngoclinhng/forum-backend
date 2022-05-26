defmodule YojeeWeb.Resolvers.Node do
  alias Yojee.Forum

  def get_node(%{type: :thread, id: id}, _resolution) do
    {:ok, Forum.get_thread(id)}
  end

  def get_node(_args, _resolution), do: {:ok, nil}
end
