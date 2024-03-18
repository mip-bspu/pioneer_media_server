defmodule MediaServer.Content.File do
  use Ecto.Schema

  import Ecto.Changeset

  alias MediaServer.Content
  alias MediaServer.Tags

  schema "files" do
    # sync
    field(:uuid, :string)
    field(:date_create, :utc_datetime)
    field(:check_sum, :string)
    field(:from, :utc_datetime)
    field(:to, :utc_datetime)
    # file
    field(:extention, :string)

    field(:name, :string)

    many_to_many :tags, Tags.Tag,
      join_through: Content.FileTag,
      on_replace: :delete,
      on_delete: :delete_all
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:extention, :name, :check_sum, :date_create, :uuid, :from, :to])
    |> put_assoc_if_exist(params[:tags])
    |> validate_required([:uuid, :date_create, :name])
  end

  defp put_assoc_if_exist(item, nil), do: item
  defp put_assoc_if_exist(item, tags), do: item |> put_assoc(:tags, tags)
end
