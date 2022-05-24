defmodule YojeeWeb.Router do
  use YojeeWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", YojeeWeb do
    pipe_through :api
  end
end
