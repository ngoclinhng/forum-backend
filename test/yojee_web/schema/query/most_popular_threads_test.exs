defmodule YojeeWeb.Schema.Query.MostPopularThreadsTest do
  use YojeeWeb.ConnCase, async: false

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

  @cache_size Application.fetch_env!(:yojee, :thread_cache_size)
  @thread_count 6

  describe "mostPopularThreads query" do
    setup do
      start_supervised!(Yojee.ThreadCache)

      threads =
        1..@thread_count
        |> Enum.map(&create_thread_with_posts/1)
        |> Enum.reverse
        |> Enum.map(&to_json/1)

      {:ok, %{threads: threads}}
    end

    1..@cache_size
    |> Enum.each(fn count ->
      test "lists top #{count} threads", %{threads: threads, conn: conn} do
        count = unquote(count)
        expected = Enum.take(threads, count)

        conn = list_popular_threads(conn, count)

        assert %{
          "data" => %{
            "mostPopularThreads" => results
          }
        } = json_response(conn, 200)

        assert results === expected
      end
    end)
  end

  # Helpers

  defp list_popular_threads(conn, count) do
    variables = %{"count" => count}

    conn
    |> post("/api", query: @query, variables: variables)
  end

  defp to_json(%{title: title, post_count: post_count} = t) do
    %{
      "id" => Node.to_global_id(t),
      "title" => title,
      "postCount" => post_count
    }
  end

  defp create_thread_with_posts(post_count) do
    title = "thread-#{System.unique_integer([:positive])}"
    {:ok, t} = Yojee.ForumBridge.create_thread(%{title: title})

    1..post_count
    |> Enum.each(fn _ ->
      content = "post-#{System.unique_integer([:positive])}"
      args = %{thread_id: t.id, content: content}
      {:ok, _} = Yojee.ForumBridge.create_post(args)
    end)

    struct(t, post_count: post_count)
  end
end
