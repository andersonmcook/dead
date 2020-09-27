defmodule Dead.World.State do
  @moduledoc false

  defstruct ~w(
    height
    previous_world
    spawnable
    width
    world
  )a

  def new(height, width) do
    %__MODULE__{
      height: height,
      previous_world: %{},
      spawnable: %{},
      width: width,
      world: %{}
    }
  end
end
