defmodule MediaServer.Devices.Device do
  use Ecto.Schema

  alias MediaServer.Devices
  alias MediaServer.Tags

  import Ecto.Changeset

  schema "devices" do
    field(:description, :string)
    field(:token, :string)
    field(:last_active, :utc_datetime)

    many_to_many :tags, Tags.Tag,
      join_through: Devices.DeviceTags,
      on_replace: :delete,
      on_delete: :delete_all
  end

  def changeset(conn, params \\ %{}) do
    IO.inspect(params)

    conn
    |> cast(params, [:description, :token])
    |> validate_required([:token, :description])
    |> validate_length(:description, min: 2, max: 50)
    |> put_assoc_if_exist(params[:tags])
  end

  defp put_assoc_if_exist(item, nil), do: item
  defp put_assoc_if_exist(item, tags), do: item |> put_assoc(:tags, tags)
end
