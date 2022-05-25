defmodule Yojee.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Yojee.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Yojee.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Yojee.DataCase
    end
  end

  setup tags do
    Yojee.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Yojee.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @doc """
  A helper functions to generate a random (printable) string of given `len`.
  """
  def random_string(len) when is_integer(len) and len > 0 do
    (for _ <- 1..len, do: rand_uniform(32, 126))
    |> List.to_string()
  end

  # Returns a random integer uniformly distributed in the range
  # `n <= X <= m`.
  #
  # If the random variable `X` is uniformly distributed in the range
  # `1 <= X <= m - n + 1`, then r.v `Y = X + n - 1` is uniformly
  # distributed in the range `n <= Y <= m`.
  # (Because we just shift X to the right).
  defp rand_uniform(n, m) do
    :rand.uniform(m - n + 1) # random X
    |> Kernel.+(n - 1)       # shift X to the right to get Y
  end

end
