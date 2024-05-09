defmodule MediaServer.Tags.Tag do
  use Ecto.Schema

  import Ecto.Changeset

  schema "tags" do
    field(:name, :string)
    field(:owner, :string, default: nil)
    # device, node
    field(:type, :string, default: "node")
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:name, :owner, :type])
    |> unique_constraint(:name)
  end
end
