defmodule MediaServer.Actions.Action do
  use Ecto.Schema

  alias MediaServer.Tags
  alias MediaServer.Content
  alias MediaServer.Actions

  import Ecto.Changeset

  schema "actions" do
    field(:name, :string)
    field(:date_create, :utc_datetime)
    field(:from, :utc_datetime)
    field(:to, :utc_datetime)
    field(:priority, :integer)

    has_many(:files, Content.Files)

    many_to_many :tags, Tags.Tag,
      join_through: Actions.ActionTags,
      on_replace: :delete,
      on_delete: :delete_all
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:name, :date_create, :from, :to, :priority])
  end
end
