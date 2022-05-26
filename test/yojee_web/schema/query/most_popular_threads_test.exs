defmodule YojeeWeb.Schema.Query.MostPopularThreadsTest do
  use YojeeWeb.ConnCase, async: true

  import Yojee.Factory, only: [threads_with_posts_fixture: 1]

  alias YojeeWeb.Schema.Node

  @query """
  query listMostPopularThreads($count: Int!) {
    mostPopularThreads(count: $count) {
      id
      title
      postCount
    }
  }
  """

  describe "mostPopularThreads query" do
    setup do
      threads = threads_with_posts_fixture(4)
      {:ok, %{threads: threads}}
    end

    test "requests top 1 threads", %{threads: threads, conn: conn} do
      [_, _, _, d] = threads
      conn = list_most_popular_threads(conn, 1)

      assert %{
        "data" => %{
          "mostPopularThreads" => popularThreads
        }
      } = json_response(conn, 200)

      assert [
        %{"id" => to_gid(d), "title" => d.title, "postCount" => 3}
      ] === popularThreads
    end

    test "requests top 2 threads", %{threads: threads, conn: conn} do
      [_, _, c, d] = threads
      conn = list_most_popular_threads(conn, 2)

      assert %{
        "data" => %{
          "mostPopularThreads" => popularThreads
        }
      } = json_response(conn, 200)

      assert [
        %{"id" => to_gid(d), "title" => d.title, "postCount" => 3},
        %{"id" => to_gid(c), "title" => c.title, "postCount" => 2}
      ] === popularThreads
    end

    test "requests top 3 threads", %{threads: threads, conn: conn} do
      [_, b, c, d] = threads
      conn = list_most_popular_threads(conn, 3)

      assert %{
        "data" => %{
          "mostPopularThreads" => popularThreads
        }
      } = json_response(conn, 200)

      assert [
        %{"id" => to_gid(d), "title" => d.title, "postCount" => 3},
        %{"id" => to_gid(c), "title" => c.title, "postCount" => 2},
        %{"id" => to_gid(b), "title" => b.title, "postCount" => 1}
      ] === popularThreads
    end

    test "requests top 4 threads", %{threads: threads, conn: conn} do
      [a, b, c, d] = threads
      conn = list_most_popular_threads(conn, 4)

      assert %{
        "data" => %{
          "mostPopularThreads" => popularThreads
        }
      } = json_response(conn, 200)

      assert [
        %{"id" => to_gid(d), "title" => d.title, "postCount" => 3},
        %{"id" => to_gid(c), "title" => c.title, "postCount" => 2},
        %{"id" => to_gid(b), "title" => b.title, "postCount" => 1},
        %{"id" => to_gid(a), "title" => a.title, "postCount" => 0}
      ] === popularThreads
    end

    test "requests top 5 threads", %{threads: threads, conn: conn} do
      [a, b, c, d] = threads
      conn = list_most_popular_threads(conn, 5)

      assert %{
        "data" => %{
          "mostPopularThreads" => popularThreads
        }
      } = json_response(conn, 200)

      assert [
        %{"id" => to_gid(d), "title" => d.title, "postCount" => 3},
        %{"id" => to_gid(c), "title" => c.title, "postCount" => 2},
        %{"id" => to_gid(b), "title" => b.title, "postCount" => 1},
        %{"id" => to_gid(a), "title" => a.title, "postCount" => 0}
      ] === popularThreads
    end

    test "requests top 1000 threads", %{threads: threads, conn: conn} do
      [a, b, c, d] = threads
      conn = list_most_popular_threads(conn, 1000)

      assert %{
        "data" => %{
          "mostPopularThreads" => popularThreads
        }
      } = json_response(conn, 200)

      assert [
        %{"id" => to_gid(d), "title" => d.title, "postCount" => 3},
        %{"id" => to_gid(c), "title" => c.title, "postCount" => 2},
        %{"id" => to_gid(b), "title" => b.title, "postCount" => 1},
        %{"id" => to_gid(a), "title" => a.title, "postCount" => 0}
      ] === popularThreads
    end
  end

  defp list_most_popular_threads(conn, count) do
    variables = %{"count" => count}

    conn
    |> post("/api", query: @query, variables: variables)
  end

  defp to_gid(thread), do: Node.to_global_id(thread)

end
