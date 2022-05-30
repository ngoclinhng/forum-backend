# Forum GraphQL Server

[launch graphiql on Heroku](https://intense-tor-69986.herokuapp.com/graphiql)

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

### Most popular threads.

The first straightforward option is to add an additional column named
`post_count` to the `threads` table. Whenever clients ask for the top N
threads, all we have to do is to sort the threads in descending order of
their post count and return the top N. Not only does this add an extra
`4 bytes` to each and every thread row (given the type of `post_count` is
integer); this also causes nasty race condition:

  - Thread X has no posts yet, so its `post_count` is `0`.

  - Client A and B insert a post to X **at the exact same time**. By the
    nature of database transaction, both A and B see `0` as X's `post_count`.

  - So when both A and B finish, the `post_count` of X would be `1` intead of
    `2`.

The second option is to join the threads table with the posts table, group
them by thread id, and count the number of posts for each groups. This
solution works, but it does not scale well:

```elixir
def list_popular_threads(n) when is_integer(n) and n > 0 do
  Thread
  |> with_post_count()
  |> order_by([t, p], desc: count(p.id))
  |> limit(^n)
  |> Repo.all
end
```

The third option is to somehow cache the IDs of top N popular threads in
memory. This guarantees to be fast, but at a cost: we have to make sure
our cache correctly reflects the state of the database at any moment in time.

We implemented both options 2 and 3 with the help of a [cache server](lib/yojee/thread_cache.ex), a [bridge module](lib/yojee/forum_bridge.ex), and a few [environment variables](https://github.com/ngoclinhng/forum-backend/blob/306269874f25fa2d3dd0b07b2489bde0c66905d8/config/test.exs#L31).

### Pagination

To allow our React client to paginate through a long list of threads and
posts, we implemented cursor-based pagination based on [GraphQL Cursor Connections Specification](https://relay.dev/graphql/connections.htm).

Even though [absinthe_relay](https://hexdocs.pm/absinthe_relay/readme.html)
advertises itself to support cursor-based pagination, it actually uses the
combination of `LIMIT` and `OFFSET` to fetch data under the hood. This style
of pagination has the following drawbacks:

  - Users would end of with duplicate data or even worse, lost data while
    navigating through pages.

  - The time complexity to fetch data is linear (in terms of `OFFSET`). This
    is unaffordable when the number of items (threads/posts) is large.

To overcome the shortcomings of `absinthe_relay`, we implemented a [custom connection](lib/yojee_web/resolvers/connection.ex). It uses the encoded id as the
cursor and fetches data using the combination of `WHERE`, `ORDER_BY` and
`LIMIT` (e.g., `WHERE id > 10 ORDER BY id DESC LIMIT 5`).