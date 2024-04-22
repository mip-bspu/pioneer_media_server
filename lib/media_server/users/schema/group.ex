defmodule MediaServer.Users.Group do
  use Ecto.Schema

  import Ecto.Changeset

  schema "groups" do
    field(:name, :string)
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_format(:name, ~r/^[A-Z]+$/)
  end
end
