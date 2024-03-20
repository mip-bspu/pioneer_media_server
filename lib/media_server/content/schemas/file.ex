defmodule MediaServer.Content.File do
  use Ecto.Schema

  import Ecto.Changeset

  alias MediaServer.Actions

  schema "files" do
    # sync
    field(:uuid, :string)
    field(:check_sum, :string)

    field(:name, :string)
    field(:extention, :string)

    belongs_to(:action, Actions.Action)
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:extention, :name, :check_sum, :uuid])
    # |> put_assoc_if_exist(params[:tags])
    |> validate_required([:uuid, :name])
  end

  defp put_assoc_if_exist(item, nil), do: item
  defp put_assoc_if_exist(item, tags), do: item |> put_assoc(:tags, tags)
end
