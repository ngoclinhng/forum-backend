defmodule Yojee.ForumBridgeTest do
  use Yojee.DataCase, async: false

  import Yojee.Factory, only: [insert!: 1]

  alias Yojee.ForumBridge
  alias Yojee.Forum.{Thread, Post}
  alias Yojee.Utils

  describe "create_thread/1" do
    setup do
      start_supervised!(Yojee.ThreadCache)
      :ok
    end

    test "with valid data inserts thread" do
      assert {:ok, thread} =
        ForumBridge.create_thread(%{title: "Test title"})

      assert %Thread{} = thread
      assert thread.title === "Test title"
      assert thread.post_count === 0

      assert_cache_state_is([{thread.id, 0}])
    end

    test "with invalid data returns error changeset" do
      assert {:error, changeset} = ForumBridge.create_thread(%{title: nil})
      assert %Ecto.Changeset{} = changeset
      assert_cache_state_is([])
    end

    test "trims whitespaces on both sides of title" do
      assert {:ok, thread} =
        ForumBridge.create_thread(%{title: "  Test title "})

      assert %Thread{} = thread
      assert thread.title === "Test title"
      assert thread.post_count === 0

      assert_cache_state_is([{thread.id, 0}])
    end

    test "requires title to have at least 3 characters long" do
      assert {:error, changeset} = ForumBridge.create_thread(%{title: "ab"})
      assert %{title: ["should be at least 3 character(s)"]} =
        errors_on(changeset)
      assert_cache_state_is([])
    end

    test "requires title to have at most 140 characters long" do
      s = "a" <> Utils.random_string(139) <> "b"
      assert String.length(s) === 141
      assert {:error, changeset} = ForumBridge.create_thread(%{title: s})
      assert %{title: ["should be at most 140 character(s)"]} =
        errors_on(changeset)
      assert_cache_state_is([])
    end
  end

  describe "create_post/1" do
    setup do
      start_supervised!(Yojee.ThreadCache)
      thread = insert!(:thread)
      {:ok, %{thread: thread}}
    end

    test "with valid data inserts post", %{thread: thread} do
      args = %{thread_id: thread.id, content: "sample post"}

      assert {:ok, post} = ForumBridge.create_post(args)
      assert %Post{} = post
      assert post.content === "sample post"
      assert post.thread_id === thread.id

      assert_cache_state_is([{thread.id, 1}])
    end

    test "trims whitespaces on both sides of post", %{thread: thread} do
      args = %{thread_id: thread.id, content: "   sample post  "}

      assert {:ok, post} = ForumBridge.create_post(args)
      assert %Post{} = post
      assert post.content === "sample post"
      assert post.thread_id === thread.id

      assert_cache_state_is([{thread.id, 1}])
    end

    test "with invalid data returns error changeset", %{thread: thread} do
      args = %{thread_id: thread.id, content: " "}
      assert {:error, changeset} = ForumBridge.create_post(args)
      assert %Ecto.Changeset{} = changeset
      assert_cache_state_is([])
    end

    test "creates post with max-length content", %{thread: thread} do
      content = "a" <> Utils.random_string(9_998) <> "b"
      assert String.length(content) === 10_000

      args = %{thread_id: thread.id, content: content}
      assert {:ok, post} = ForumBridge.create_post(args)
      assert %Post{} = post
      assert post.content === content
      assert post.thread_id === thread.id

      assert_cache_state_is([{thread.id, 1}])
    end

    test "requires content length <= 10_000 chars", %{thread: thread} do
      content = "a" <> Utils.random_string(9_999) <> "b"
      assert String.length(content) === 10_001

      args = %{thread_id: thread.id, content: content}
      assert {:error, changeset} = ForumBridge.create_post(args)
      assert %{content: ["should be at most 10000 character(s)"]} =
        errors_on(changeset)

      assert_cache_state_is([])
    end
  end

  describe "list_popular_threads/1" do
    @cache_size Application.fetch_env!(:yojee, :thread_cache_size)
    @thread_count 6

    setup do
      start_supervised!(Yojee.ThreadCache)

      threads =
        1..@thread_count
        |> Enum.map(&create_thread_with_posts/1)
        |> Enum.reverse

      {:ok, %{threads: threads}}
    end

    test "setup test", %{threads: threads} do
      assert length(threads) === @thread_count

      state =
        threads
        |> Enum.map(&({&1.id, &1.post_count}))
        |> Enum.take(@cache_size)

      assert_cache_state_is(state)
    end

    1..@cache_size
    |> Enum.each(fn count ->
      test "lists top #{count} threads", %{threads: threads} do
        count = unquote(count)
        expected = Enum.take(threads, count)
        assert ForumBridge.list_popular_threads(count) === expected
      end
    end)
  end

  defp assert_cache_state_is(state) do
    assert :sys.get_state(Yojee.ThreadCache) === state
  end

  defp create_thread_with_posts(post_count) do
    title = "thread-#{System.unique_integer([:positive])}"
    {:ok, t} = ForumBridge.create_thread(%{title: title})

    1..post_count
    |> Enum.each(fn _ ->
      content = "post-#{System.unique_integer([:positive])}"
      args = %{thread_id: t.id, content: content}
      {:ok, _} = ForumBridge.create_post(args)
    end)

    struct(t, post_count: post_count)
  end

end
