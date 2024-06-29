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
    |> validate_length(:name, min: 3, max: 60)
    |> unique_constraint(:name)
  end
end
