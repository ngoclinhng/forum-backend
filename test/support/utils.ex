defmodule Yojee.Utils do
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
