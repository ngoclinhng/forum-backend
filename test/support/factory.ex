defmodule Yojee.Factory do
  alias Yojee.Repo
  alias Yojee.Forum.{Thread, Post}

  # Factories

  def build(:thread) do
    %Thread{title: "thread-#{System.unique_integer([:positive])}"}
  end

  def build(:post) do
    %Post{content: "post-#{System.unique_integer([:positive])}"}
  end

  # Convenience API

  def build(factory_name, attributes) do
    factory_name
    |> build()
    |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    factory_name
    |> build(attributes)
    |> Repo.insert!()
  end

  def insert_thread_with_posts!(num_posts)
  when is_integer(num_posts) and num_posts > 0 do
    posts = for _ <- 1..num_posts, do: build(:post)
    build(:thread, posts: posts)
    |> Repo.insert!
  end

  def insert_thread_with_posts!(_num_posts) do
    build(:thread, posts: [])
    |> Repo.insert!
  end

  def threads_with_posts_fixture(num_threads \\ 5)
  when is_integer(num_threads) and num_threads > 0 do
    0..(num_threads - 1)
    |> Enum.map(&insert_thread_with_posts!/1)
  end
end
