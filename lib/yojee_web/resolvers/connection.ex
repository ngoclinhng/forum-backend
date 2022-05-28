defmodule YojeeWeb.Resolvers.Connection do
  @moduledoc """
  Custom Relay connection.

  Even though `absinthe_relay` implements Relay-style pagination, the
  underlying query actually uses the combination of LIMIT and OFFSET to
  fetch data (see `Absinthe.Relay.Connection.from_query/4`). This style of
  pagination has the following drawbacks:

    - Users would end up with duplicate data or even worse, lost data
      while navigating through pages.

    - The time complexity to fetch data is linear (in terms of OFFSET).
      This is unaffordable when the number of items is large.

  This custom Connection uses a unique, sequential key (e.g., integer `id`)
  along with the WHERE, ORDER BY, and LIMIT clauses to fetch the data.
  (e.g., `WHERE id > 10 ORDER BY id LIMIT 5`).
  """

  import Ecto.Query

  alias YojeeWeb.Resolvers.Cursor

  @doc """
  Similar to `Absinthe.Relay.Connection.from_query/4`.
  """
  def from_query(_query, _repo_fun, %{first: _, last: _}, _opts) do
    {:error, "The combination of :first and :last is unsupported"}
  end

  def from_query(_query, _repo_fun, %{before: _, after: _}, _opts) do
    {:error, "The combination of :before and :after is unsupported"}
  end

  def from_query(_query, _repo_fun, %{first: _, before: _}, _opts) do
    {:error, "The combination of :first and :before is unsupported"}
  end

  def from_query(_query, _repo_fun, %{last: _, after: _}, _opts) do
    {:error, "The combination of :last and :after is unsupported"}
  end

  # Arguments are exactly the same as that of
  # `Absinthe.Relay.Connection.from_query/4`, except the last argument
  # `opts`. Here `opts` must contain a tuple `{key, order}` where
  # `key` will be used to encode cursor and `order` is either `:asc` or
  # `:desc`. (`key` will be ordered using this order).
  #
  # For example, if you pass {:id, :asc}, all entries will be ordered by
  # id ascending.
  def from_query(query, repo_fun, pagination_args, opts) do
    pagination_args
    |> put_default_args()
    |> convert_cursor()
    |> case do
         {:ok, args} ->
           do_from_query(query, repo_fun, args, opts)

         _ ->
           # TODO: Be specific about why we get here.
           {:error, :unknown}
       end
  end

  # Helpers.

  defp do_from_query(query, repo_fun, args, [{key, _}] = opts) do
    {records, has_more} = do_query(query, repo_fun, args, opts)

    edges =
      records
      |> Enum.map(&(convert_record_to_edge(&1, key)))

    page_info  =
      get_page_info(args, has_more)
      |> Map.put(:start_cursor, start_cursor(edges))
      |> Map.put(:end_cursor, end_cursor(edges))

    {:ok, %{edges: edges, page_info: page_info}}
  end

  # SELECT * FROM some_table
  # WHERE `key` > `value` (or WHERE `key` < `value`)
  # ORDER BY `key` ASC    (or ORDER BY `key` DESC )
  # LIMIT `count`.
  defp do_query(
    query,
    repo_fun,
    %{first: count, after: value},
    [{key, order}]
  ) do
    records =
      query
      |> where_key(key, after: value, order: order)
      |> order_by([{^order, ^key}])
      |> limit_plus_one(count)
      |> repo_fun.()

    has_more = length(records) > count
    records = drop_last(records, has_more)
    {records, has_more}
  end

  # If we want the last 3 records before id 6, ascending, we need to
  # reverse the order of the query to descending:
  # SELECT * FROM some_table
  # WHERE id < 6
  # ORDER BY id DESC
  # LIMIT 3
  # This gets the correct records, but in wrong order, so we'll have
  # to reverse them.
  defp do_query(
    query,
    repo_fun,
    %{last: count, before: value},
    [{key, order}]
  ) do
    order = flip_order(order)

    records =
      query
      |> where_key(key, after: value, order: order)
      |> order_by([{^order, ^key}])
      |> limit_plus_one(count)
      |> repo_fun.()
      |> Enum.reverse

    has_more = length(records) > count
    records = drop_first(records, has_more)
    {records, has_more}
  end

  defp get_page_info(%{first: :infinity, after: cursor}, _has_more) do
    %{
      has_previous_page: !is_nil(cursor),
      has_next_page: false
    }
  end

  defp get_page_info(%{first: _count, after: cursor}, has_more) do
    %{
      has_previous_page: !is_nil(cursor),
      has_next_page: has_more
    }
  end

  defp get_page_info(%{last: :infinity, before: cursor}, _has_more) do
    %{
      has_previous_page: false,
      has_next_page: !is_nil(cursor)
    }
  end

  defp get_page_info(%{last: _count, before: cursor}, has_more) do
    %{
      has_previous_page: has_more,
      has_next_page: !is_nil(cursor)
    }
  end

  # Start cursor of a page
  defp start_cursor([]), do: nil
  defp start_cursor([%{cursor: cursor} | _rest]), do: cursor

  # End cursor of a page
  defp end_cursor([]), do: nil
  defp end_cursor(list) when is_list(list) do
    list
    |> List.last()
    |> Map.get(:cursor)
  end

  # Convert whatever shit we got from the database to an edge.
  defp convert_record_to_edge(%{} = record, key) when is_atom(key) do
    %{
      node: record,
      cursor: Cursor.from_key(record, key)
    }
  end

  # Default `:after` to `nil` if not provided.
  defp put_default_args(%{first: _count} = args) do
    args
    |> Map.put_new(:after, nil)
  end

  # default `:before` to `nil` if not provided.
  defp put_default_args(%{last: _count} = args) do
    args
    |> Map.put_new(:before, nil)
  end

  # No `:first` provided means client want to fetch all entries after
  # the given cursor.
  #
  # ---------------+----+----+----+---.....
  #                ^
  #                |
  #              cursor
  #
  # TODO: We should not allow this.
  defp put_default_args(%{after: _cursor} = args) do
    args
    |> Map.put_new(:first, :infinity)
  end

  # No `:last` privided means client want to fetch all entries before
  # the given cursor.
  #
  # ...----+----+----+----+-----------
  #                       ^
  #                     cursor
  #
  # TODO: We should not allow this.
  defp put_default_args(%{before: _cursor} = args) do
    args
    |> Map.put_new(:last, :infinity)
  end

  # Neither `:first` nor `:after` were provided, which means client
  # to fetch all entries.
  #
  # TODO: We should not allow this.
  defp put_default_args(args) do
    args
    |> Map.put_new(:first, :infinity)
    |> Map.put_new(:after, nil)
  end

  # Get first `count` entries from the beginning, so cursor is nil.
  defp convert_cursor(%{first: _count, after: nil} = args) do
    {:ok, args}
  end

  # Get last `count` entries from the end, so cursor is nil.
  defp convert_cursor(%{last: _count, before: nil} = args) do
    {:ok, args}
  end

  # We decode the given `cursor` to get the key value. Note that, this
  # only works iff the key was encoded using `Cursor.from_key/2` function.
  defp convert_cursor(%{first: _, after: cursor} = args) do
    case Cursor.to_key(cursor) do
      {:ok, value} ->
        {:ok, Map.put(args, :after, value)}

      _ ->
        {:error, :invalid_cursor}
    end
  end

  # We decode the given `cursor` to get the key value. Note that, this
  # only works iff the key was encoded using `Cursor.from_key/2` function.
  defp convert_cursor(%{last: _, before: cursor} = args) do
    case Cursor.to_key(cursor) do
      {:ok, value} ->
        {:ok, Map.put(args, :before, value)}

      _ ->
        {:error, :invalid_cursor}
    end
  end

  defp where_key(query, _key, after: nil, order: _order) do
    query
  end

  defp where_key(query, key, after: value, order: :asc) do
    query
    |> where([q], field(q, ^key) > ^value)
  end

  defp where_key(query, key, after: value, order: :desc) do
    query
    |> where([q], field(q, ^key) < ^value)
  end

  defp limit_plus_one(query, :infinity) do
    query
  end

  defp limit_plus_one(query, count) when is_integer(count) do
    query
    |> limit(^count + 1)
  end

  defp drop_last(list, true) when is_list(list) and length(list) > 0 do
    list
    |> Enum.reverse()
    |> tl()
    |> Enum.reverse()
  end

  defp drop_last(list, _) do
    list
  end

  defp drop_first([_ | tail], true), do: tail
  defp drop_first(list, _), do: list

  defp flip_order(:asc), do: :desc
  defp flip_order(:desc), do: :asc
end
