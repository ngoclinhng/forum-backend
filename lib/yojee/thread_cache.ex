defmodule Yojee.ThreadCache do
  @moduledoc """
  A process that caches the most popular threads for expedient access.

  The reason why this cache was born is this: it is too time-consuming if
  every time clients ask for the top N popular threads, we join the threads
  table with the posts table, count the number of posts for each, sort them
  in descending order based on the number of posts they have, and then
  select the top N.

  Basic idea:

    1. When our application starts, we load the top N threads from the
       database and make them the initial state of our GenServer.

    2. A post was inserted into thread X:

       - If X is present in the state: increment the number of posts for X
         by 1.

       - Otherwise: go to the database, load the number of posts for X, and
         based on the results, either X would end up in the state (and
         some other thread would be out) or not.

    3. A post was removed from thread X:

       - If X is present: refresh the server (step 1). We can't simply
         decrement the number of posts X has by 1, because there may be
         some other threads in the database that have more posts than X.

       - Otherwise: do nothing.

    4. A thread was deleted: refresh the state if X is present, otherwise,
       do nothing.

    5. A thread X was created: if the number of threads in our cache is
       less than N, add X to the state, otherwise, do nothing.

  It seems like silly to pay such an expensive cost for each post
  insert/remove operation, but:

    1. The process of updating the server state happens in the background
       asynchronously, so we don't make our users wait: when a user creates
       a post, he'll get it immediately (without having to wait for the
       update process to finish).

    2. In the real world application where the number of threads is large,
       the probability of users interacting with old threads are low
       (given that we present them from newest to oldest threads), so by
       inreasing the cache size (if you were to ask me to show 10 most
       populars, then I would cache, say, 100 popular threads along with
       100 newest threads) we would reduce the probability of making a
       trip to the database after post insert/remove operations.
  """

  use GenServer

  alias Yojee.Forum

  @cache_size Application.fetch_env!(:yojee, :thread_cache_size)

  @events [:post_added, :post_removed, :thread_added, :thread_removed]

  # Client (Public) Interface

  @doc """
  Starts the cache process.
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Returns the list of at most `count` popular threads.
  """
  def popular_threads(count) when is_integer(count)
  and count <= @cache_size do
    GenServer.call(__MODULE__, {:popular_threads, count})
  end

  @doc """
  Updates the cache after the specified `event` has happended. This event
  would probably have changed the `post_count` of the thread whose id is
  given by `thread_id`.

  Note that this is an asynchronous call.
  """
  def update_cache(event, thread_id) when event in @events do
    GenServer.cast(__MODULE__, {:update_cache, event, thread_id})
  end

  # Server Callbacks

  @impl true
  def init(_args) do
    state = init_state();
    {:ok, state}
  end

  @impl true
  def handle_call({:popular_threads, count}, _from, state) do
    reply =
      state
      |> Enum.take(count)
      |> state_keys()
      |> Forum.list_threads()

    {:reply, reply, state}
  end

  @impl true
  def handle_cast({:update_cache, :post_added, thread_id}, state) do
    new_state = state_increment(state, thread_id)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_cache, :post_removed, thread_id}, state) do
    new_state = state_decrement(state, thread_id)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_cache, :thread_added, thread_id}, state) do
    new_state = state_append(state, {thread_id, 0})
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_cache, :thread_removed, thread_id}, state) do
    new_state = state_remove(state, thread_id)
    {:noreply, new_state}
  end

  # Helpers

  defp init_state() do
    Forum.list_most_popular_threads(@cache_size)
    |> Enum.map(&({&1.id, &1.post_count}))
  end

  defp state_append(state, {thread_id, post_count}) do
    case length(state) < @cache_size do
      true ->
        state ++ [{thread_id, post_count}]
      false ->
        state
    end
  end

  defp state_remove(state, thread_id) do
    case state_has_key?(state, thread_id) do
      false ->
        state
      true ->
        init_state()
    end
  end

  defp state_increment(state, thread_id) do
    case state_has_key?(state, thread_id) do
      true ->
        state_update(state, thread_id, &(&1 + 1))
      false ->
        thread = Forum.get_thread(thread_id)
        state_insert(state, thread)
    end
  end

  defp state_decrement(state, thread_id) do
    case state_has_key?(state, thread_id) do
      false ->
        state
      true ->
        init_state()
    end
  end

  defp state_insert(state, nil), do: state
  defp state_insert(state, %{id: id, post_count: post_count}) do
    [{id, post_count} | state]
    |> List.keysort(1)
    |> Enum.reverse()
    |> Enum.take(@cache_size)
  end

  defp state_has_key?(state, key) do
    state
    |> Enum.any?(&(elem(&1, 0) == key))
  end

  defp state_keys(state) do
    state
    |> Enum.map(&(elem(&1, 0)))
  end

  defp state_update(state, key, fun) do
    state
    |> Enum.map(fn
      {^key, value} ->
        {key, fun.(value)}
      {k, v} ->
        {k, v}
    end)
  end
end
