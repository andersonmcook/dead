defmodule Dead.WorldServer do
  @moduledoc false

  use GenServer, restart: :transient

  alias Dead.World.State

  @options ~w(dh dz h n z)a

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def tick(pid) do
    GenServer.call(pid, :tick)
  end

  def world(pid) do
    GenServer.call(pid, :world)
  end

  def reset(pid) do
    GenServer.call(pid, :reset)
  end

  @impl true
  def init({height, width}) do
    {:ok, State.new(height, width), {:continue, :create_world}}
  end

  @impl true
  def handle_call(:reset, _from, state) do
    # Kill all
    Registry.dispatch(
      Dead.Registry,
      "entity",
      &Enum.each(&1, fn {pid, _} ->
        DynamicSupervisor.terminate_child(Dead.DynamicSupervisor, pid)
      end),
      parallel: true
    )

    world = new_world(state.height, state.width)
    {:reply, world, %{state | world: world}}
  end

  @impl true
  def handle_call(:tick, _from, state) do
    # TODO: each entity needs to know the world server? or we call to the world via a registry?
    Registry.dispatch(Dead.Registry, "entity", &Enum.each(&1, fn {_pid, _} -> nil end))
  end

  @impl true
  def handle_call(:world, _from, state) do
    {:reply, state.world, state}
  end

  @impl true
  def handle_continue(:create_world, state) do
    {:ok, _} = Registry.register(Dead.Registry, "world", [])
    {:noreply, %{state | world: new_world(state.height, state.width)}}
  end

  @spec new(non_neg_integer, non_neg_integer) :: %{
          height: non_neg_integer,
          width: non_neg_integer,
          world: map
        }
  defp new_world(height, width) do
    for x <- 1..width, y <- 1..height, into: %{} do
      @options
      |> Enum.random()
      |> case do
        entity when entity in [:h, :z] ->
          {:ok, pid} =
            DynamicSupervisor.start_child(Dead.DynamicSupervisor, {Dead.EntityServer, entity})

          {pid, {entity, x, y}}

        tile ->
          {make_ref(), {tile, x, y}}
      end
    end
  end
end

# recursively detect collisions
# or first one wins
# zombies spawn when space is empty
# game is over when no more humans or zombies remain
