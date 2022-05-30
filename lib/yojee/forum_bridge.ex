defmodule Yojee.ForumBridge do
  @moduledoc """
  This module acts as a bridge between the Forum context and the
  ThreadCache process.
  """

  alias Yojee.ThreadCache
  alias Yojee.Forum

  @use_cache Application.fetch_env!(:yojee, :use_thread_cache)

  @doc """
  See `Forum.create_thread/1`
  """
  def create_thread(attrs) do
    create_thread(attrs, @use_cache)
  end

  @doc """
  See `Forum.create_post/1`
  """
  def create_post(attrs) do
    create_post(attrs, @use_cache)
  end

  @doc """
  See `Forum.list_most_popular_threads/1`.
  """
  def list_popular_threads(count) when is_integer(count) and count > 0 do
    ThreadCache.popular_threads(count)
  end

  # Helpers

  defp create_thread(attrs, false) do
    Forum.create_thread(attrs)
  end

  defp create_thread(attrs, true) do
    Forum.create_thread(attrs)
    |> case do
         {:ok, thread} ->
           :ok = ThreadCache.update_cache(:thread_added, thread.id)
           {:ok, thread}
         {:error, changeset} ->
           {:error, changeset}
       end
  end

  defp create_post(attrs, false) do
    Forum.create_post(attrs)
  end

  defp create_post(attrs, true) do
    Forum.create_post(attrs)
    |> case do
         {:ok, post} ->
           :ok = ThreadCache.update_cache(:post_added, post.thread_id)
           {:ok, post}
         {:error, changeset} ->
           {:error, changeset}
       end
  end

end
