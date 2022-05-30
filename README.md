# Forum GraphQL Server

To start the server:

  * Install dependencies with `mix deps.get`
  * Create and migrate database with `mix ecto.setup`
  * Start GraphQL endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`http://localhost:4000/graphiql`](http://localhost:4000/graphiql) from your browser.


## The big picture

  ![App design](app_overview.png)

### The Data Model:

The Data Model has two entities: **Thread** and **Post**. They are stored
in the PostgreSQL database under tables `threads` and `posts`, respectively.

### Ecto Schemas

We have corresponding Ecto Schemas map to each of thoes database tables:
`%Thread{}` maps to `threads` and `%Post{}` maps to `posts`.

### Forum context

Sitting on top of the Data Model and Ecto Schemas is the Phoenix context
`Forum.ex`. It encapsulates the details for creating posts, querying the
most popular threads, etc...

### GraphQL API

The final layer of our application is the GraphQL API powered by Absinthe.
The queries and mutations documents supported by the API are defined in the
graphQL Schema. To execute thoes documents, we have a thin layer of Resolver
modules that lean on the Phoenix context modules to fetch, create and update
data.

## The details

### Pagination

To allow our React client to paginate through a long list of threads and
posts, we implement cursor-based pagination based on [GraphQL Cursor Connections Specification](https://relay.dev/graphql/connections.htm).

Even though [absinthe_relay](https://hexdocs.pm/absinthe_relay/readme.html)
advertises itself to support cursor-based pagination, it actually uses the
combination of `LIMIT` and `OFFSET` to fetch data under the hood. This style
of pagination has the following drawbacks:

  - Users would end of with duplicate data or even worse, lost data while
    navigating through pages.

  - The time complexity to fetch data is linear (in terms of `OFFSET`). This
    is unaffordable when the number of items (threads/posts) is large.

To overcome the shortcomings of `absinthe_relay`, we implement a [custom connection](lib/yojee_web/resolvers/connection.ex). It uses the encoded id as the
cursor and fetches data using the combination of `WHERE`, `ORDER_BY` and
`LIMIT` (e.g., `WHERE id > 10 ORDER BY id LIMIT 5`).