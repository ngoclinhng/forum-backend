defmodule Yojee.ForumTest do
  use Yojee.DataCase, asyn: true

  import Yojee.Factory, only: [insert!: 1]

  alias Yojee.Forum
  alias Yojee.Forum.Thread

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
      s = String.duplicate("titl ", 28) <> "e"
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
end
