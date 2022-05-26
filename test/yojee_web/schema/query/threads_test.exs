defmodule YojeeWeb.Schema.Query.ThreadsTest do
  use YojeeWeb.ConnCase, async: true

  import Yojee.Factory, only: [
    insert_thread_with_posts!: 1
  ]

  alias YojeeWeb.Schema.Node

  @query """
  query ListThread($after: String, $before: String, $first: Int, $last: Int) {
    threads(after: $after, before: $before, first: $first, last: $last) {
      edges {
        node {
          id
          title
          postCount
        }
        cursor
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
      }
    }
  }
  """

  describe "threads query" do
    setup do
      threads =
        [0, 2, 0, 1, 3, 2]
        |> Enum.map(&insert_thread_with_posts!/1)
        |> Enum.reverse()
        |> Enum.map(&convert_to_node/1)

      {:ok, %{threads: threads}}
    end

    [0, 1, 2, 3, 4, 5, 6, 10, 100]
    |> Enum.each(fn first ->
      test "first #{first}", %{threads: threads, conn: conn} do
        first = unquote(first)
        has_next_page = first < length(threads)

        variables = %{"first" => first}
        conn = post(conn, "/api", query: @query, variables: variables)

        assert %{
          "data" => %{
            "threads" => %{
              "edges" => edges,
              "pageInfo" => %{
                "hasNextPage" => ^has_next_page,
                "hasPreviousPage" => false
              }
            }
          }
        } = json_response(conn, 200)

        assert remove_cursor(edges) == Enum.take(threads, first)
      end
    end)

    (for cursor <- 1..6, first <- 0..5, do: {first, cursor})
    |> Enum.each(fn {first, cursor} ->
      test "first #{first} after cursor #{cursor}",
      %{threads: threads, conn: conn} do
        first = unquote(first)
        cursor = unquote(cursor)
        tail = Enum.drop(threads, cursor)

        # Grab the true cursor
        cursor = cursor_at(conn, cursor)

        # Query first after cursor.

        has_next_page = first < length(tail)
        variables = %{"first" => first, "after" => cursor}
        conn = post(conn, "/api", query: @query, variables: variables)

        assert %{
          "data" => %{
            "threads" => %{
              "edges" => edges,
              "pageInfo" => %{
                "hasNextPage" => ^has_next_page,
                "hasPreviousPage" => true
              }
            }
          }
        } = json_response(conn, 200)

        assert remove_cursor(edges) == Enum.take(tail, first)
      end
    end)

    (for cursor <- 1..6, last <- 0..5, do: {last, cursor})
    |> Enum.each(fn {last, cursor} ->
      test "last #{last} before cursor #{cursor}",
      %{threads: threads, conn: conn} do
        last = unquote(last)
        cursor = unquote(cursor)

        # 1    2    3    4    5    6
        # +----+----+----+----+----+
        #                     ^
        #                     |
        #                   cursor
        head = Enum.take(threads, cursor - 1)

        # Grab the true cursor
        cursor = cursor_at(conn, cursor)

        # Query last after cursor.

        has_previous_page = last < length(head)
        variables = %{"last" => last, "before" => cursor}
        conn = post(conn, "/api", query: @query, variables: variables)

        assert %{
          "data" => %{
            "threads" => %{
              "edges" => edges,
              "pageInfo" => %{
                "hasNextPage" => true,
                "hasPreviousPage" => ^has_previous_page
              }
            }
          }
        } = json_response(conn, 200)

        expected =
          head
          |> Enum.reverse()
          |> Enum.take(last)
          |> Enum.reverse()

        assert remove_cursor(edges) == expected
      end
    end)
  end

  defp convert_to_node(%{title: title, posts: posts} = thread) do
    %{
      "node" => %{
        "id" => Node.to_global_id(thread),
        "title" => title,
        "postCount" => length(posts)
      }
    }
  end

  defp remove_cursor(edges) do
    edges
    |> Enum.map(&(Map.delete(&1, "cursor")))
  end

  defp cursor_at(conn, index) when is_integer(index) and index > 0 do
    variables = %{"first" => index}
    conn = post(conn, "/api", query: @query, variables: variables)

    %{
      "data" => %{
        "threads" => %{"edges" => edges}
      }
    } = json_response(conn, 200)

    edges
    |> List.last()
    |> Map.fetch!("cursor")
  end

end
