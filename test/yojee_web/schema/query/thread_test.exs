defmodule YojeeWeb.Schema.Query.ThreadTest do
  use YojeeWeb.ConnCase, async: true

  import Yojee.Factory, only: [
    insert!: 1,
    insert_thread_with_posts!: 1
  ]

  @query """
  query getThread($id: ID!) {
    thread(id: $id) {
      id
      title
      postCount
    }
  }
  """

  test "thread query returns the thread with a given id", %{conn: conn} do
    thread = insert!(:thread)
    variables = %{"id" => thread.id}
    conn = post(conn, "/api", query: @query, variables: variables)

    assert %{
      "data" => %{
        "thread" => %{
          "id" => to_string(thread.id),
          "title" => thread.title,
          "postCount" => 0
        }
      }
    } === json_response(conn, 200)
  end

  test "thread query returns the thread along with its postCount",
    %{conn: conn} do
    thread = insert_thread_with_posts!(3)
    variables = %{"id" => thread.id}
    conn = post(conn, "/api", query: @query, variables: variables)

    assert %{
      "data" => %{
        "thread" => %{
          "id" => to_string(thread.id),
          "title" => thread.title,
          "postCount" => 3
        }
      }
    } === json_response(conn, 200)
  end

end
