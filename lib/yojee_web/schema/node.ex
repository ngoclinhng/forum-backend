defmodule YojeeWeb.Schema.Node do
  alias Yojee.Forum.{Thread, Post}
  alias Absinthe.Relay.Node
  alias YojeeWeb.Schema.Schema

  @doc """
  Type resolver for Absinthe Relay node interface.
  """
  def type(%Thread{}, _absinthe_resolution), do: :thread
  def type(%Post{}, _absinthe_resolution), do: :post
  def type(_struct, _absinthe_resolution), do: nil

  @doc """
  A helper function to convert to global ID from the given internal ID.
  """
  def to_global_id(%Thread{id: internal_id}) do
    Node.to_global_id(:thread, internal_id, Schema)
  end
  def to_global_id(%Post{id: internal_id}) do
    Node.to_global_id(:post, internal_id, Schema)
  end

  @doc """
  A helper function to convert to internal ID from the given global ID.
  """
  def from_global_id(global_id) do
    Node.from_global_id(global_id, Schema)
  end

end
