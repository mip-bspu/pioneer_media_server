defmodule MediaServer.Files.File do
  use Ecto.Schema

  import Ecto.Changeset

  alias MediaServer.Actions

  schema "files" do
    field(:uuid, :string)
    field(:check_sum, :string)
    field(:name, :string)
    field(:extention, :string)
    field(:timelive_image, :integer, default: 15)

    belongs_to(:action, Actions.Action)
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:extention, :name, :check_sum, :uuid, :action_id, :timelive_image])
    |> validate_required([:uuid, :name])
    |> unique_constraint(:uuid)
  end
end
