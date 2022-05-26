defmodule YojeeWeb.Schema.Mutation.CreateThreadTest do
  use YojeeWeb.ConnCase, async: true

  @query """
  mutation createThread($input: CreateThreadInput!) {
    createThread(input: $input) {
      thread {
        title
        postCount
      }
    }
  }
  """

  test "createThread mutation creates a thread", %{conn: conn} do
    conn = create_thread(conn, %{title: "test title"})

    assert %{
      "data" => %{
        "createThread" => %{
          "thread" => ret
        }
      }
    } = json_response(conn, 200)

    assert ret === %{
      "title" => "test title",
      "postCount" => 0
    }
  end

  test "createThread mutation trims whitespaces on both side of title",
    %{conn: conn} do
    conn = create_thread(conn, %{"title" => "  test title "})

    assert %{
      "data" => %{
        "createThread" => %{
          "thread" => ret
        }
      }
    } = json_response(conn, 200)

    assert ret === %{
      "title" => "test title",
      "postCount" => 0
    }
  end

  test "createThread mutation fails if title < 3 characters",
    %{conn: conn} do
    conn = create_thread(conn, %{"title" => "ab"})

    assert %{
      "data" => %{"createThread" => nil},
      "errors" => [
        %{
          "message" => "Could not create thread",
          "details" => %{
            "title" => ["should be at least 3 character(s)"]
          },
          "locations" => [%{"column" => 3, "line" => 2}],
          "path" => ["createThread"]
        }
      ]
    } === json_response(conn, 200)
  end

  test "createThread mutation fails if title > 140 characters",
    %{conn: conn} do
    s = String.duplicate("titl ", 28) <> "e"
    assert String.length(s) === 141

    conn = create_thread(conn, %{"title" => s})

    assert %{
      "data" => %{"createThread" => nil},
      "errors" => [
        %{
          "message" => "Could not create thread",
          "details" => %{
            "title" => ["should be at most 140 character(s)"]
          },
          "locations" => [%{"column" => 3, "line" => 2}],
          "path" => ["createThread"]
        }
      ]
    } === json_response(conn, 200)
  end

  # Helpers

  defp create_thread(conn, input) do
    payload = %{
      query: @query,
      variables: %{"input" => input}
    }

    post(conn, "/api", payload)
  end

end
