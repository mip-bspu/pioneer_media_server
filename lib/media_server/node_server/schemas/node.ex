defmodule MediaServer.NodeServer.Node do
  use Ecto.Schema

  import Ecto.Changeset

  schema "nodes" do
    field(:name, :string)
    field(:ping, :integer)
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:name, :ping])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
