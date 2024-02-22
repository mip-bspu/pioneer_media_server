defmodule MediaServer.Content.File do
  use Ecto.Schema

  import Ecto.Changeset

  alias MediaServer.Content

  schema "files" do
    # sync
    field(:uuid, :string)
    field(:date_create, :utc_datetime)
    field(:check_sum, :string)

    # file
    field(:extention, :string)

    field(:name, :string)

    many_to_many :tags, Content.Tag,
      join_through: Content.FileTag
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:extention, :name, :check_sum, :date_create, :uuid])
    |> cast_assoc(:tags,  required: true)
    |> validate_required([:uuid, :date_create, :name])
  end
end
