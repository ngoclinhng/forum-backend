defmodule YojeeWeb.Schema.Mutation.CreatePostTest do
  use YojeeWeb.ConnCase, async: true

  import Yojee.Factory, only: [insert!: 1]

  alias Yojee.Utils

  @query """
  mutation createPost($threadId: ID!, $content: String!) {
    createPost(threadId: $threadId, content: $content) {
      content
      thread {
        id
        title
      }
    }
  }
  """

  describe "createPost mutation" do
    setup do
      thread = insert!(:thread)
      {:ok, %{thread: thread}}
    end

    test "with valid data creates post", ctx do
      %{thread: thread, conn: conn} = ctx

      args = %{"threadId" => thread.id, "content" => "sample post"}
      conn = create_post(conn, args)

      assert %{
        "data" => %{
          "createPost" => %{
            "content" => "sample post",
            "thread" => %{
              "id" => to_string(thread.id),
              "title" => thread.title
            }
          }
        }
      } === json_response(conn, 200)
    end

    test "trims whitespaces on both side of content", ctx do
      %{thread: thread, conn: conn} = ctx

      args = %{"threadId" => thread.id, "content" => "  sample post    "}
      conn = create_post(conn, args)

      assert %{
        "data" => %{
          "createPost" => %{
            "content" => "sample post",
            "thread" => %{
              "id" => to_string(thread.id),
              "title" => thread.title
            }
          }
        }
      } === json_response(conn, 200)
    end

    test "creates post with max-length content", ctx do
      %{thread: thread, conn: conn} = ctx

      content = "a" <> Utils.random_string(9_998) <> "b"
      assert String.length(content) === 10_000

      args = %{"threadId" => thread.id, "content" => content}
      conn = create_post(conn, args)

      assert %{
        "data" => %{
          "createPost" => %{
            "content" => content,
            "thread" => %{
              "id" => to_string(thread.id),
              "title" => thread.title
            }
          }
        }
      } === json_response(conn, 200)
    end

    test "fails if content is empty string", ctx do
      %{thread: thread, conn: conn} = ctx

      args = %{"threadId" => thread.id, "content" => "  "}
      conn = create_post(conn, args)

      assert %{
        "data" => %{"createPost" => nil},
        "errors" => [
          %{
            "message" => "Could not create post",
            "details" => %{"content" => ["can't be blank"]},
            "locations" => [%{"column" => 3, "line" => 2}],
            "path" => ["createPost"]
          }
        ]
      } === json_response(conn, 200)
    end

    test "fails if content is too long", ctx do
      %{thread: thread, conn: conn} = ctx

      # We have to do this since `create_post` will trim whitespaces
      # on both sides of the input string.
      content = "a" <> Utils.random_string(9_999) <> "b"
      assert String.length(content) === 10_001

      args = %{"threadId" => thread.id, "content" => content}
      conn = create_post(conn, args)

      assert %{
        "data" => %{"createPost" => nil},
        "errors" => [
          %{
            "message" => "Could not create post",
            "details" => %{
              "content" => ["should be at most 10000 character(s)"]
            },
            "locations" => [%{"column" => 3, "line" => 2}],
            "path" => ["createPost"]
          }
        ]
      } === json_response(conn, 200)
    end

    # TODO: this only works if primary key is integer.
    test "fails if the given thread doesn't exist", %{conn: conn} do
      args = %{"threadId" => -1, "content" => "sample test"}
      conn = create_post(conn, args)

      assert %{
        "data" => %{"createPost" => nil},
        "errors" => [
          %{
            "message" => "Could not create post",
            "details" => %{"thread" => ["does not exist"]},
            "locations" => [%{"column" => 3, "line" => 2}],
            "path" => ["createPost"]
          }
        ]
      } === json_response(conn, 200)
    end
  end

  # Helpers

  defp create_post(conn, variables) do
    conn
    |> post("/api", %{query: @query, variables: variables})
  end

end
