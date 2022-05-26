defmodule YojeeWeb.Schema.Query.ThreadTest do
  use YojeeWeb.ConnCase, async: true

  import Yojee.Factory, only: [
    insert!: 1,
    insert_thread_with_posts!: 1
  ]

  alias YojeeWeb.Schema.Node

  @query """
  query getThread($id: ID!) {
    node(id: $id) {
      __typename
      ... on Thread {
        id
        title
        postCount
      }
    }
  }
  """

  test "thread query returns the thread with a given id", %{conn: conn} do
    thread = insert!(:thread)
    global_id = Node.to_global_id(thread)

    variables = %{"id" => global_id}
    conn = post(conn, "/api", query: @query, variables: variables)

    assert %{
      "data" => %{
        "node" => %{
          "__typename" => "Thread",
          "id" => global_id,
          "title" => thread.title,
          "postCount" => 0
        }
      }
    } === json_response(conn, 200)
  end

  test "thread query returns the thread along with its postCount",
    %{conn: conn} do
    thread = insert_thread_with_posts!(3)
    global_id = Node.to_global_id(thread)

    variables = %{"id" => global_id}
    conn = post(conn, "/api", query: @query, variables: variables)

    assert %{
      "data" => %{
        "node" => %{
          "__typename" => "Thread",
          "id" => global_id,
          "title" => thread.title,
          "postCount" => 3
        }
      }
    } === json_response(conn, 200)
  end

end
