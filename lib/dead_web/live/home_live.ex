defmodule DeadWeb.HomeLive do
  use DeadWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) and is_nil(socket.assigns[:world_pid]) do
      {:ok, pid} =
        DynamicSupervisor.start_child(Dead.DynamicSupervisor, {Dead.WorldServer, {10, 10}})

      {:ok, assign(socket, world: Dead.WorldServer.world(pid), world_pid: pid)}
    else
      {:ok, assign(socket, world: %{}, world_pid: nil)}
    end
  end

  @impl true
  def handle_event("reset", _args, socket) do
    {:noreply, assign(socket, world: Dead.WorldServer.reset(socket.assigns.world_pid))}
  end
end

# start a world
# world starts humans and zombies
# world tells humans and zombies to pick a move
# h & z respond with moves
# world calculates any collisions and kills
