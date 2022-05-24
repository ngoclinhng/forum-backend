defmodule YojeeWeb.Schema.Schema do
  use Absinthe.Schema

  alias YojeeWeb.Resolvers

  # Queries

  query do
    @desc "Get the thread whose id is given by id"
    field :thread, :thread do
      arg :id, non_null(:id)
      resolve &Resolvers.Forum.thread/3
    end
  end

  # Objects

  object :thread do
    @desc "The unique identifier of this thread"
    field :id, non_null(:id)

    @desc "The title of this thread"
    field :title, non_null(:string)
  end

end
