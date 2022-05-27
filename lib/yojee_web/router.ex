defmodule YojeeWeb.Router do
  use YojeeWeb, :router

  pipeline :api do
    plug CORSPlug
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :api

    forward "/api", Absinthe.Plug,
      schema: YojeeWeb.Schema.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: YojeeWeb.Schema.Schema
  end
end
