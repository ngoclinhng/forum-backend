defmodule YojeeWeb.Schema.Schema do
  use Absinthe.Schema

  # Needed for the `:datetime` type
  import_types Absinthe.Type.Custom

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Yojee.Forum
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

    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end

  object :post do
    @desc "The unique identifier of this post"
    field :id, non_null(:id)

    @desc "The (plain text) content of this post"
    field :content, non_null(:string)

    @desc "The thread to which this post belongs"
    field :thread, non_null(:thread), resolve: dataloader(Forum)

    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end

  # Absinth execution context setup.

  def context(ctx) do
    loader =
      Dataloader.new
      |> Dataloader.add_source(Forum, Forum.datasource())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
