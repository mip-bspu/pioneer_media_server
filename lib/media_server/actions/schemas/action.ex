defmodule MediaServer.Actions.Action do
  use Ecto.Schema

  alias MediaServer.Tags
  alias MediaServer.Files
  alias MediaServer.Actions

  import Ecto.Changeset

  schema "actions" do
    field(:name, :string)
    field(:uuid, :string)
    field(:date_create, :utc_datetime)
    field(:from, :date)
    field(:to, :date)
    field(:priority, :integer)

    has_many(:files, Files.File)

    many_to_many :tags, Tags.Tag,
      join_through: Actions.ActionTags,
      on_replace: :delete,
      on_delete: :delete_all
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:name, :date_create, :from, :to, :priority, :uuid])
    |> validate_required([:uuid, :name, :from, :to, :priority])
    |> validate_length(:name, min: 3, max: 60)
    |> validate_inclusion(:priority, 1..4)
    |> unique_constraint(:uuid)
    |> put_assoc_if_exist(params[:tags])
  end

  defp put_assoc_if_exist(item, nil), do: item
  defp put_assoc_if_exist(item, tags), do: item |> put_assoc(:tags, tags)
end
