defmodule Yojee.ForumTest do
  use Yojee.DataCase, async: true

  import Yojee.Factory, only: [
    insert!: 1,
    threads_with_posts_fixture: 1,
    insert_thread_with_posts!: 1
  ]

  alias Yojee.Forum
  alias Yojee.Forum.{Thread, Post}
  alias Yojee.Utils

  describe "create_thread/1" do
    test "with valid data inserts thread" do
      assert {:ok, thread} = Forum.create_thread(%{title: "Test title"})
      assert %Thread{} = thread
      assert thread.title === "Test title"
      assert thread.post_count === 0
    end

    test "with invalid data returns error changeset" do
      assert {:error, changeset} = Forum.create_thread(%{title: nil})
      assert %Ecto.Changeset{} = changeset
    end

    test "trims whitespaces on both sides of title" do
      assert {:ok, thread} = Forum.create_thread(%{title: "  Test title "})
      assert %Thread{} = thread
      assert thread.title === "Test title"
      assert thread.post_count === 0
    end

    test "requires title to have at least 3 characters long" do
      assert {:error, changeset} = Forum.create_thread(%{title: "ab"})
      assert %{title: ["should be at least 3 character(s)"]} =
        errors_on(changeset)
    end

    test "requires title to have at most 140 characters long" do
      s = "a" <> Utils.random_string(139) <> "b"
      assert String.length(s) === 141
      assert {:error, changeset} = Forum.create_thread(%{title: s})
      assert %{title: ["should be at most 140 character(s)"]} =
        errors_on(changeset)
    end
  end

  describe "get_thread/1" do
    test "returns the thread with the given id" do
      assert %Thread{id: id, title: title} = insert!(:thread)

      assert %Thread{
        id: ^id,
        title: ^title,
        post_count: 0
      } = Forum.get_thread(id)
    end

    test "returns the thread along with its post_count" do
      assert %Thread{
        id: id,
        title: title,
        posts: posts
      } = insert_thread_with_posts!(3)

      assert length(posts) === 3

      assert %Thread{
        id: ^id,
        title: ^title,
        post_count: 3
      } = Forum.get_thread(id)
    end
  end

  describe "create_post/1" do
    setup do
      thread = insert!(:thread)
      {:ok, %{thread: thread}}
    end

    test "with valid data inserts post", %{thread: thread} do
      args = %{thread_id: thread.id, content: "sample post"}
      assert {:ok, post} = Forum.create_post(args)
      assert %Post{} = post
      assert post.content === "sample post"
      assert post.thread_id === thread.id
    end

    test "trims whitespaces on both sides of post", %{thread: thread} do
      args = %{thread_id: thread.id, content: "   sample post  "}
      assert {:ok, post} = Forum.create_post(args)
      assert %Post{} = post
      assert post.content === "sample post"
      assert post.thread_id === thread.id
    end

    test "with invalid data returns error changeset", %{thread: thread} do
      args = %{thread_id: thread.id, content: " "}
      assert {:error, changeset} = Forum.create_post(args)
      assert %Ecto.Changeset{} = changeset
    end

    test "creates post with max-length content", %{thread: thread} do
      content = "a" <> Utils.random_string(9_998) <> "b"
      assert String.length(content) === 10_000

      args = %{thread_id: thread.id, content: content}
      assert {:ok, post} = Forum.create_post(args)
      assert %Post{} = post
      assert post.content === content
      assert post.thread_id === thread.id
    end

    test "requires content length <= 10_000 chars", %{thread: thread} do
      content = "a" <> Utils.random_string(9_999) <> "b"
      assert String.length(content) === 10_001

      args = %{thread_id: thread.id, content: content}
      assert {:error, changeset} = Forum.create_post(args)
      assert %{content: ["should be at most 10000 character(s)"]} =
        errors_on(changeset)
    end
  end

  describe "list_most_popular_threads/1" do
    setup do
      # 4 threads ordered by the number of posts ascending (from 0 to 3)
      threads = threads_with_posts_fixture(4)
      {:ok, %{threads: threads}}
    end

    test "setup test", %{threads: threads} do
      assert length(threads) === 4

      threads
      |> Enum.with_index()
      |> Enum.each(fn {%Thread{} = t, i} ->
        assert length(t.posts) === i
      end)
    end

    test "lists top 1 threads", %{threads: threads} do
      assert [_, _, _, d] = threads
      assert [t] = Forum.list_most_popular_threads(1)
      assert_same_thread(t, d)
      assert t.post_count === 3
    end

    test "lists top 2 threads", %{threads: threads} do
      assert [_, _, c, d] = threads
      assert [t1, t2] = Forum.list_most_popular_threads(2)

      assert_same_thread(t1, d)
      assert t1.post_count === 3

      assert_same_thread(t2, c)
      assert t2.post_count === 2
    end

    test "lists top 3 threads", %{threads: threads} do
      assert [_, b, c, d] = threads
      assert [t1, t2, t3] = Forum.list_most_popular_threads(3)

      assert_same_thread(t1, d)
      assert t1.post_count === 3

      assert_same_thread(t2, c)
      assert t2.post_count === 2

      assert_same_thread(t3, b)
      assert t3.post_count === 1
    end

    test "lists top 4 threads", %{threads: threads} do
      assert [a, b, c, d] = threads
      assert [t1, t2, t3, t4] = Forum.list_most_popular_threads(4)

      assert_same_thread(t1, d)
      assert t1.post_count === 3

      assert_same_thread(t2, c)
      assert t2.post_count === 2

      assert_same_thread(t3, b)
      assert t3.post_count === 1

      assert_same_thread(t4, a)
      assert t4.post_count === 0
    end

    test "lists top 5 threads", %{threads: threads} do
      assert [a, b, c, d] = threads
      assert [t1, t2, t3, t4] = Forum.list_most_popular_threads(5)

      assert_same_thread(t1, d)
      assert t1.post_count === 3

      assert_same_thread(t2, c)
      assert t2.post_count === 2

      assert_same_thread(t3, b)
      assert t3.post_count === 1

      assert_same_thread(t4, a)
      assert t4.post_count === 0
    end

    test "lists top 1000 threads", %{threads: threads} do
      assert [a, b, c, d] = threads
      assert [t1, t2, t3, t4] = Forum.list_most_popular_threads(1000)

      assert_same_thread(t1, d)
      assert t1.post_count === 3

      assert_same_thread(t2, c)
      assert t2.post_count === 2

      assert_same_thread(t3, b)
      assert t3.post_count === 1

      assert_same_thread(t4, a)
      assert t4.post_count === 0
    end
  end

  defp assert_same_thread(%Thread{} = t1, %Thread{} = t2) do
    assert t1.id === t2.id
    assert t1.title === t2.title
  end
end
