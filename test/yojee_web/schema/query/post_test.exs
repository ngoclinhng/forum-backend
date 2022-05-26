defmodule YojeeWeb.Schema.Query.PostTest do
  use YojeeWeb.ConnCase, async: true

  import Yojee.Factory, only: [insert_thread_with_posts!: 1]

  alias YojeeWeb.Schema.Node

  @query """
  query getPost($id: ID!) {
    node(id: $id) {
      __typename
      ... on Post {
        id
        content
        thread {
          id
          title
        }
      }
    }
  }
  """

  test "post query returns the post with the specified id", %{conn: conn} do
    thread = insert_thread_with_posts!(1)
    [post] = thread.posts
    post_gid = Node.to_global_id(post)

    variables = %{"id" => post_gid}
    conn = post(conn, "/api", query: @query, variables: variables)

    assert %{
      "data" => %{
        "node" => %{
          "__typename" => "Post",
          "id" => post_gid,
          "content" => post.content,
          "thread" => %{
            "id" => Node.to_global_id(thread),
            "title" => thread.title
          }
        }
      }
    } === json_response(conn, 200)
  end
end
