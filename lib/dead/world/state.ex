defmodule Dead.World.State do
  @moduledoc false

  defstruct ~w(
    height
    spawnable
    width
    world
  )a

  def new(height, width) do
    %__MODULE__{
      height: height,
      spawnable: %{},
      width: width,
      world: %{}
    }
  end
end
