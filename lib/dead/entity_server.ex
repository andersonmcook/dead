defmodule Dead.EntityServer do
  @moduledoc false

  use GenServer, restart: :transient

  # @moves ~w(n s e w i)a

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

  @impl true
  def handle_info({:tick, from}, state) do
    # Registry.lookup()
    {x, y} = state.coordinate

    new_coordinate =
      {Enum.random([x, min(x + 1, state.boundary.max_x), max(x - 1, state.boundary.min_x)]),
       Enum.random([y, min(y + 1, state.boundary.max_y), max(y - 1, state.boundary.min_y)])}

    send(from, {:move, new_coordinate, state.type, self()})
    {:noreply, %{state | coordinate: new_coordinate}}
  end

  @impl true
  def terminate(reason, _state) do
    IO.inspect({"entity died", reason})
  end
end
