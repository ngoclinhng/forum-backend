defmodule YojeeWeb.Schema.Query.ThreadTest do
  use YojeeWeb.ConnCase, async: true

  import Yojee.Factory, only: [insert!: 1]

  @query """
  query getThread($id: ID!) {
    thread(id: $id) {
      id
      title
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
          "title" => thread.title
        }
      }
    } === json_response(conn, 200)
  end

end
