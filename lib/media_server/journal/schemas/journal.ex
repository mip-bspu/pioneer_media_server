defmodule MediaServer.Journal.Journal do
  use Ecto.Schema

  import Ecto.Changeset

  schema "journal" do
    field(:action, :string)
    field(:content_uuid, :string)
    field(:priority, :integer)
    field(:token, :string)

    timestamps(type: :utc_datetime)
  end

  def changeset(conn, params \\ %{}) do
    conn
    |> cast(params, [:action, :content_uuid, :priority])
    |> validate_required([:action, :content_uuid, :priority])
  end
end
