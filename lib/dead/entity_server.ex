defmodule Dead.EntityServer do
  @moduledoc false

  use GenServer, restart: :transient

  def start_link(value) do
    GenServer.start_link(__MODULE__, value)
  end

  @impl true
  def init(value) do
    {:ok, value, {:continue, :register}}
  end

  @impl true
  def handle_continue(:register, state) do
    {:ok, _} = Registry.register(Dead.Registry, "entity", [])

    {:noreply, state}
  end
end
