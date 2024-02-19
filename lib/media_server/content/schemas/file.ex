defmodule MediaServer.Content.File do
  use Ecto.Schema

  import Ecto.Changeset

  schema "files" do
    # sync
    field(:uuid, :string)
    field(:date_create, :utc_datetime)
    field(:check_sum, :string)

    # file
    field(:extention, :string)

    field(:name, :string)
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:extention, :name, :check_sum, :date_create, :uuid])
    |> validate_required([:uuid, :date_create, :name])
  end
end
