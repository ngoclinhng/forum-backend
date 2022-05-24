defmodule Yojee.Factory do
  alias Yojee.Repo
  alias Yojee.Forum.Thread

  # Factories

  def build(:thread) do
    %Thread{title: "thread-#{System.unique_integer([:positive])}"}
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
end
