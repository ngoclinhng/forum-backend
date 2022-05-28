defmodule YojeeWeb.Resolvers.Connection do
  @moduledoc """
  Custom Relay connection.

  Even though `absinthe_relay` implements Relay-style pagination, the
  underlying query actually uses the combination of LIMIT and OFFSET to
  fetch data (see `Absinthe.Relay.Connection.query/4`). This style of
  pagination has the following drawbacks:

    - Users would end up with duplicate data or even worse, lost data
      while navigating through pages.

    - The time complexity to fetch data is linear (in terms of OFFSET).
      This is unaffordable when the number of items is large.

  This custom Connection uses a unique, sequential key (e.g., integer `id`)
  along with the WHERE, ORDER BY, and LIMIT clauses to fetch the data.
  (e.g., `WHERE id > 10 ORDER BY id LIMIT 5`).
  """
end
