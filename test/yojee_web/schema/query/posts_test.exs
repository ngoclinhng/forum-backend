defmodule YojeeWeb.Schema.Query.PostsTest do
  use YojeeWeb.ConnCase, async: true

  import Yojee.Factory, only: [
    insert_thread_with_posts!: 1
  ]

  alias YojeeWeb.Schema.Node

  @query """
  query ListPost(
    $threadId: ID!,
    $after: String,
    $before: String,
    $first: Int,
    $last: Int
  ) {
    node(id: $threadId) {
      __typename
      ... on Thread {
        id
        title
        posts(first: $first, last: $last, before: $before, after: $after) {
          edges {
            node {
              id
              content
            }
            cursor
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
        }
      }
    }
  }
  """

  describe "posts query" do
    setup do
      thread =
        insert_thread_with_posts!(6)
        |> convert_thread_to_map()

      {:ok, %{thread: thread}}
    end

    [0, 1, 2, 3, 4, 5, 6, 10, 100]
    |> Enum.each(fn first ->
      test "first #{first}", %{thread: thread, conn: conn} do
        first = unquote(first)
        %{id: thread_id, title: thread_title, posts: posts} = thread

        has_next_page = first < length(posts)
        variables = %{"first" => first, "threadId" => thread_id}
        conn = post(conn, "/api", query: @query, variables: variables)

        assert %{
          "data" => %{
            "node" => %{
              "__typename" => "Thread",
              "id" => ^thread_id,
              "title" => ^thread_title,
              "posts" => %{
                "edges" => edges,
                "pageInfo" => %{
                  "hasNextPage" => ^has_next_page,
                  "hasPreviousPage" => false
                }
              }
            }
          }
        } = json_response(conn, 200)

        expected_posts = Enum.take(posts, first)
        assert convert_edges_to_posts(edges) == expected_posts
      end
    end)

    (for cursor <- 1..6, first <- 0..5, do: {first, cursor})
    |> Enum.each(fn {first, cursor} ->
      test "first #{first} after cursor #{cursor}", ctx do
        %{thread: thread, conn: conn} = ctx
        first = unquote(first)
        cursor = unquote(cursor)

        %{id: thread_id, title: thread_title, posts: posts} = thread
        tail = Enum.drop(posts, cursor)
        cursor = post_cursor_at(conn, cursor, thread_id)

        variables = %{
          "first" => first,
          "after" => cursor,
          "threadId" => thread_id
        }

        conn = post(conn, "/api", query: @query, variables: variables)
        has_next_page = first < length(tail)

        assert %{
          "data" => %{
            "node" => %{
              "__typename" => "Thread",
              "id" => ^thread_id,
              "title" => ^thread_title,
              "posts" => %{
                "edges" => edges,
                "pageInfo" => %{
                  "hasNextPage" => ^has_next_page,
                  "hasPreviousPage" => true
                }
              }
            }
          }
        } = json_response(conn, 200)

        expected_posts = Enum.take(tail, first)
        assert convert_edges_to_posts(edges) == expected_posts
      end
    end)

    (for cursor <- 1..6, last <- 0..5, do: {last, cursor})
    |> Enum.each(fn {last, cursor} ->
      test "last #{last} before cursor #{cursor}", ctx do
        %{thread: thread, conn: conn} = ctx
        last = unquote(last)
        cursor = unquote(cursor)

        %{id: thread_id, title: thread_title, posts: posts} = thread
        head = Enum.take(posts, cursor - 1)
        cursor = post_cursor_at(conn, cursor, thread_id)

        variables = %{
          "last" => last,
          "before" => cursor,
          "threadId" => thread_id
        }

        conn = post(conn, "/api", query: @query, variables: variables)
        has_previous_page = last < length(head)

        assert %{
          "data" => %{
            "node" => %{
              "__typename" => "Thread",
              "id" => ^thread_id,
              "title" => ^thread_title,
              "posts" => %{
                "edges" => edges,
                "pageInfo" => %{
                  "hasNextPage" => true,
                  "hasPreviousPage" => ^has_previous_page
                }
              }
            }
          }
        } = json_response(conn, 200)

        expected_posts =
          head
          |> Enum.reverse()
          |> Enum.take(last)
          |> Enum.reverse()

        assert convert_edges_to_posts(edges) == expected_posts
      end
    end)
  end

  # Helpers

  defp convert_thread_to_map(%{title: title, posts: posts} = thread) do
    posts =
      posts
      |> Enum.reverse()
      |> Enum.map(&convert_post_to_map/1)

    %{
      id: Node.to_global_id(thread),
      title: title,
      posts: posts
    }
  end

  defp convert_post_to_map(%{content: content} = post) do
    %{
      "id" => Node.to_global_id(post),
      "content" => content
    }
  end

  defp convert_edges_to_posts(edges) do
    edges
    |> Enum.map(&(Map.fetch!(&1, "node")))
  end

  defp post_cursor_at(conn, index, thread_id)
  when is_integer(index) and index > 0 do
    variables = %{"first" => index, "threadId" => thread_id}
    conn = post(conn, "/api", query: @query, variables: variables)

    %{
      "data" => %{
        "node" => %{
          "posts" => %{"edges" => edges}
        }
      }
    } = json_response(conn, 200)

    edges
    |> List.last()
    |> Map.fetch!("cursor")
  end

end
