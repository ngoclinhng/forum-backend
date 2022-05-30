defmodule Yojee.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      Application.fetch_env!(:yojee, :use_thread_cache)
      |> children_list()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Yojee.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    YojeeWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Helpers.

  defp children_list(_use_thread_cache = false) do
    [
      # Start the Ecto repository
      Yojee.Repo,

      # Start the Telemetry supervisor
      YojeeWeb.Telemetry,

      # Start the PubSub system
      {Phoenix.PubSub, name: Yojee.PubSub},

      # Start the Endpoint (http/https)
      YojeeWeb.Endpoint
      # Start a worker by calling: Yojee.Worker.start_link(arg)
      # {Yojee.Worker, arg}
    ]
  end

  defp children_list(_use_thread_cache = true) do
    children_list(false)
    |> Kernel.++([Yojee.ThreadCache])
  end

end
