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