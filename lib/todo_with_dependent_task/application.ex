defmodule TodoWithDependentTask.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      TodoWithDependentTask.Repo,
      # Start the Telemetry supervisor
      TodoWithDependentTaskWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: TodoWithDependentTask.PubSub},
      # Start the Endpoint (http/https)
      TodoWithDependentTaskWeb.Endpoint
      # Start a worker by calling: TodoWithDependentTask.Worker.start_link(arg)
      # {TodoWithDependentTask.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TodoWithDependentTask.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TodoWithDependentTaskWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
