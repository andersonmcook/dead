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
    Registry.dispatch(
      Dead.Registry,
      "entity",
      &Enum.each(&1, fn {pid, _} -> send(pid, {:tick, self()}) end)
    )

    {:reply, state.world, state}
  end

  @impl true
  def handle_call(:world, _from, state) do
    {:reply, state.world, state}
  end

  @impl true
  def handle_continue(:create_world, state) do
    {:ok, _} = Registry.register(Dead.Registry, "world", [])
    world = new_world(state.height, state.width)

    {:noreply, %{state | previous_world: Map.new(world, fn {k, v} -> {v, k} end), world: world}}
  end

  @impl true
  def handle_info({:move, move, type, from}, state) do
    # check if they can move
    # let them move into empty squares
    # {entities, "stopping for now"} =
    #   case state.world do
    #     {^move, {^type, ^from}} -> "figure out"
    #     {^move, {_type, nil}} -> "k"
    #   end

    # FIXME clear out after the piece has moved
    # could store both the coordinate and entity as separate keys in the same map
    # this is basically the same as storing the floor and the entities above the floor in the same map vs 2 maps
    # when we collide in a move we kill one of them from the map, place the blood on the floor and remove the victor from the previous space
    # i think we should store the previous location of each so we know where to remove them from

    previous_world = Map.new(state.world, fn {k, v} -> {v, k} end)

    world =
      state.world
      |> Map.update!(move, &collide(&1, type, from))
      |> Map.put(previous_world[{type, from}], {:n, nil})

    {:noreply, %{state | previous_world: previous_world, world: world}}
    # {:noreply, state}
  end

  # @spec new_world(non_neg_integer, non_neg_integer) :: %{
  #         height: non_neg_integer,
  #         width: non_neg_integer,
  #         world: map
  #       }
  defp new_world(height, width) do
    for x <- 1..width, y <- 1..height, into: %{} do
      coordinate = {x, y}

      @options
      |> Enum.random()
      |> case do
        entity when entity in [:h, :z] ->
          {:ok, pid} =
            DynamicSupervisor.start_child(
              Dead.DynamicSupervisor,
              {Dead.EntityServer,
               %{
                 boundary: %{
                   max_x: width,
                   max_y: height,
                   min_x: 1,
                   min_y: 1
                 },
                 type: entity,
                 coordinate: coordinate
               }}
            )

          # {pid, {entity, x, y}}
          {coordinate, {entity, pid}}

        tile ->
          # {make_ref(), {tile, x, y}}
          {coordinate, {tile, nil}}
      end
    end
  end

  defp collide({_tile, nil}, entity, pid) do
    {entity, pid}
  end

  defp collide({entity, pid}, entity, pid) do
    {entity, pid}
  end

  defp collide({existing_entity, existing_pid}, new_entity, new_pid) do
    [lives, dies] = Enum.shuffle([{existing_entity, existing_pid}, {new_entity, new_pid}])
    # IO.inspect({lives, dies}, label: "\nlives/dies")
    # Process could be dead already?
    {_pid, pid} = dies

    if Process.alive?(pid) do
      :ok = DynamicSupervisor.terminate_child(Dead.DynamicSupervisor, pid)
    end

    lives
  end
end

# recursively detect collisions
# or first one wins
# zombies spawn when space is empty
# game is over when no more humans or zombies remain
