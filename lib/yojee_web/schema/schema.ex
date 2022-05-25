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

  # Mutations

  mutation do
    @desc "Create a thread with the given attributes"
    field :create_thread, :thread do
      arg :title, non_null(:string)
      resolve &Resolvers.Forum.create_thread/3
    end

    @desc "Create a post with the given attributes"
    field :create_post, :post do
      arg :thread_id, non_null(:id)
      arg :content, non_null(:string)
      resolve &Resolvers.Forum.create_post/3
    end
  end

  # Objects

  object :thread do
    @desc "The unique identifier of this thread"
    field :id, non_null(:id)

    @desc "The title of this thread"
    field :title, non_null(:string)
  end

  object :post do
    @desc "The unique identifier of this post"
    field :id, non_null(:id)

    @desc "The (plain text) content of this post"
    field :content, non_null(:string)
  end

end
