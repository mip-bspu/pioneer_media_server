defmodule MediaServer.Content.Tag do
  use Ecto.Schema

  import Ecto.Changeset

  schema "tags" do
    field(:name, :string)
    field(:owner, :string, default: nil)
    # field(:type, :string)
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:name, :owner])
    |> unique_constraint(:name)
  end
end
