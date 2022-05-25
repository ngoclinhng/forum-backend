defmodule Yojee.ForumTest do
  use Yojee.DataCase, async: true

  import Yojee.Factory, only: [insert!: 1]

  alias Yojee.Forum
  alias Yojee.Forum.{Thread, Post}

  describe "create_thread/1" do
    test "with valid data inserts thread" do
      assert {:ok, thread} = Forum.create_thread(%{title: "Test title"})
      assert %Thread{} = thread
      assert thread.title === "Test title"
    end

    test "with invalid data returns error changeset" do
      assert {:error, changeset} = Forum.create_thread(%{title: nil})
      assert %Ecto.Changeset{} = changeset
    end

    test "trims whitespaces on both sides of title" do
      assert {:ok, thread} = Forum.create_thread(%{title: "  Test title "})
      assert %Thread{} = thread
      assert thread.title === "Test title"
    end

    test "requires title to have at least 3 characters long" do
      assert {:error, changeset} = Forum.create_thread(%{title: "ab"})
      assert %{title: ["should be at least 3 character(s)"]} =
        errors_on(changeset)
    end

    test "requires title to have at most 140 characters long" do
      s = random_string(141)
      assert String.length(s) === 141
      assert {:error, changeset} = Forum.create_thread(%{title: s})
      assert %{title: ["should be at most 140 character(s)"]} =
        errors_on(changeset)
    end
  end

  describe "get_thread/1" do
    test "returns the thread with the given id" do
      assert %Thread{id: id, title: title} = insert!(:thread)
      assert %Thread{id: ^id, title: ^title} = Forum.get_thread(id)
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

    test "creates max-lenght post", %{thread: thread} do
      content = random_string(10_000)
      assert String.length(content) === 10_000

      args = %{thread_id: thread.id, content: content}
      assert {:ok, post} = Forum.create_post(args)
      assert %Post{} = post
      assert post.content === String.trim(content)
      assert post.thread_id === thread.id
    end

    test "requires post length <= 10_000 characters", %{thread: thread} do
      content = random_string(10_001)
      assert String.length(content) === 10_001

      args = %{thread_id: thread.id, content: content}
      assert {:error, changeset} = Forum.create_post(args)
      assert %{content: ["should be at most 10000 character(s)"]} =
        errors_on(changeset)
    end
  end
end
