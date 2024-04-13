defmodule MediaServer.Tags.Tag do
  use Ecto.Schema

  import Ecto.Changeset

  schema "tags" do
    field(:name, :string)
    field(:owner, :string, default: nil)
    # device, action
    field(:type, :string, default: "action")
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:name, :owner, :type])
    |> unique_constraint(:name)
  end
end
