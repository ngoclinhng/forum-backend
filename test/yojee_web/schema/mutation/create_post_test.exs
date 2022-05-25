defmodule YojeeWeb.Schema.Mutation.CreatePostTest do
  use YojeeWeb.ConnCase, async: true

  import Yojee.Factory, only: [insert!: 1]

  alias Yojee.Utils

  @query """
  mutation CreatePost($threadId: ID!, $content: String!) {
    createPost(threadId: $threadId, content: $content) {
      content
    }
  }
  """

  describe "createPost mutation" do
    setup do
      thread = insert!(:thread)
      {:ok, %{thread: thread}}
    end

    test "with valid data creates post", %{thread: thread} do
      args = %{"threadId" => thread.id, "content" => "sample post"}
      conn = create_post_request(args)

      assert %{
        "data" => %{
          "createPost" => %{
            "content" => "sample post"
          }
        }
      } === json_response(conn, 200)
    end

    test "trims whitespaces on both side of content", %{thread: thread} do
      args = %{"threadId" => thread.id, "content" => "  sample post    "}
      conn = create_post_request(args)

      assert %{
        "data" => %{
          "createPost" => %{
            "content" => "sample post"
          }
        }
      } === json_response(conn, 200)
    end

    test "creates post with max-length content", %{thread: thread} do
      content = "a" <> Utils.random_string(9_998) <> "b"
      assert String.length(content) === 10_000

      args = %{"threadId" => thread.id, "content" => content}
      conn = create_post_request(args)

      assert %{
        "data" => %{
          "createPost" => %{
            "content" => content
          }
        }
      } === json_response(conn, 200)
    end

    test "fails if content is empty string", %{thread: thread} do
      args = %{"threadId" => thread.id, "content" => "  "}
      conn = create_post_request(args)

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

    test "fails if content is too long", %{thread: thread} do
      # We have to do this since `create_post` will trim whitespaces
      # on both sides of the input string.
      content = "a" <> Utils.random_string(9_999) <> "b"
      assert String.length(content) === 10_001

      args = %{"threadId" => thread.id, "content" => content}
      conn = create_post_request(args)

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
    test "fails if the given thread doesn't exist" do
      args = %{"threadId" => -1, "content" => "sample test"}
      conn = create_post_request(args)

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

  defp create_post_request(variables) do
    build_conn()
    |> post("/api", %{query: @query, variables: variables})
  end

end
