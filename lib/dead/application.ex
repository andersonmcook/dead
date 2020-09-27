defmodule Dead.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      DeadWeb.Telemetry,
      {Phoenix.PubSub, name: Dead.PubSub},
      {DynamicSupervisor, strategy: :one_for_one, name: Dead.DynamicSupervisor},
      {Registry, keys: :duplicate, name: Dead.Registry, partitions: System.schedulers_online()},
      DeadWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Dead.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DeadWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
