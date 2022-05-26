defmodule YojeeWeb.Schema.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  # Needed for the `:datetime` type
  import_types Absinthe.Type.Custom

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Yojee.Forum
  alias YojeeWeb.Resolvers

  # Absinthe Relay node interface.
  node interface do
    resolve_type &YojeeWeb.Schema.Node.type/2
  end

  # Absinthe Relay connections.
  connection node_type: :thread
  connection node_type: :post

  # Queries

  query do
    # This will provide a unified interface to query for any object that
    # conforms to the node interface. For example, this is how we query
    # for a thread object:
    #
    #   node(id: "VGhyZWFkOjU=") {
    #     __typename
    #     ... on Thread {
    #       id
    #       title
    #     }
    #   }
    node field do
      resolve &Resolvers.Forum.get_node/3
    end

    @desc "Returns the top `count` most popular threads"
    field :most_popular_threads, list_of(:thread) do
      arg :count, non_null(:integer)
      resolve &Resolvers.Forum.most_popular_threads/3
    end

    @desc "Returns a page of threads paginated according to Relay style"
    connection field :threads, node_type: :thread do
      resolve &Resolvers.Forum.threads/3
    end
  end

  # Mutations

  mutation do
    @desc "Create a thread with the given attributes"
    payload field :create_thread do
      input do
        field :title, non_null(:string)
      end

      output do
        field :thread, :thread
      end

      resolve &Resolvers.Forum.create_thread/3
    end

    @desc "Create a post with the given attributes"
    payload field :create_post do
      input do
        field :thread_id, non_null(:id)
        field :content, non_null(:string)
      end

      output do
        field :post, :post
      end

      resolve &Resolvers.Forum.create_post/3
    end
  end

  # Objects

  # The `node` macro turns our old friend `:thread` into a node.
  #
  # What it does is to add an extra field named `:id` to our `:thread`
  # object. This `:id` is the global unique ID as opposed to the
  # internal `:id` (in our case, auto-incremented integer).
  #
  # But how exactly does Absinthe resolve this global `:id`?
  #
  #   - First, Absinthe uses pattern-matching to extract the internal
  #     id based on the node interface resolver defined above.
  #
  #   - Second, it uses `Relay.Node.to_global_id/3` to convert the
  #     internal id obtained from step 1 to the global ID (which looks
  #     like a random string). The inverse transformation is
  #     `Relay.Node.from_global_id/2`.
  #
  # What are the benefits of doing this?
  #
  #   - It provides a unified interface to query for an object in the
  #     using a global ID. For example, instead of implementing multiple
  #     queries such as `getObjectA`, `getObjectB`, `getObjectC`, etc...
  #     we only need to implement one single query `node(id: GlobalID!)`.
  #
  #   - Our internal IDs are not exposed to client. It would be a nightmare
  #     to expose internal IDs to the client of our APIs if, for example,
  #     we decide to switch to `binary_id` (as opposed to`integer`) at some
  #     point down the road.
  #
  #   - The global ID will serve as cursor in cursor-based pagination.
  #     This would allow for faster pagination as well as
  #     infinite-scrolling effect on client side.
  node object :thread do
    @desc "The title of this thread"
    field :title, non_null(:string)

    @desc "The number of posts within this thread"
    field :post_count, non_null(:integer)

    @desc "a page of posts paginated according to Relay style"
    connection field :posts, node_type: :post do
      resolve &Resolvers.Forum.posts/3
    end

    field :inserted_at, non_null(:datetime)
    field :updated_at, non_null(:datetime)
  end

  node object :post do
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
