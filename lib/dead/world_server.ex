defmodule Dead.WorldServer do
  @moduledoc false

  use GenServer, restart: :transient

  @options ~w(dh dz h n z)a

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def world(pid) do
    GenServer.call(pid, :world)
  end

  def reset(pid) do
    GenServer.call(pid, :reset)
  end

  @impl true
  def init({height, width}) do
    {:ok, %{height: height, width: width, world: %{}}, {:continue, :create_world}}
  end

  @impl true
  def handle_call(:reset, _from, state) do
    Registry.dispatch(
      Dead.Registry,
      "entity",
      &Enum.each(&1, fn {pid, _} ->
        DynamicSupervisor.terminate_child(Dead.DynamicSupervisor, pid)
      end),
      parallel: true
    )

    world = new(state.height, state.width)
    {:reply, world, %{state | world: world}}
  end

  @impl true
  def handle_call(:world, _from, state) do
    {:reply, state.world, state}
  end

  @impl true
  def handle_continue(:create_world, state) do
    {:noreply, %{state | world: new(state.height, state.width)}}
  end

  @spec new(non_neg_integer, non_neg_integer) :: %{
          height: non_neg_integer,
          width: non_neg_integer,
          world: map
        }
  defp new(height, width) do
    for x <- 0..width, y <- 0..height, into: %{} do
      @options
      |> Enum.random()
      |> case do
        entity when entity in [:h, :z] ->
          {:ok, pid} =
            DynamicSupervisor.start_child(Dead.DynamicSupervisor, {Dead.EntityServer, entity})

          {{x, y}, {entity, pid}}

        tile ->
          {{x, y}, {tile, nil}}
      end
    end
  end
end
