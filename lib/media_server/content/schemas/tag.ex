defmodule MediaServer.Content.Tag do
  use Ecto.Schema

  import Ecto.Changeset

  schema "tags" do
    field(:name, :string)
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:name])
  end
end
