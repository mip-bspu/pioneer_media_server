defmodule MediaServer.Devices do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Devices
  alias MediaServer.Tags

  import Ecto.Query

  def get_by_token(token) do
    Devices.Device
    |> Repo.get_by(token: token)
    |> Repo.preload(:tags)
  end

  def get_devices_by_tags(tags) do
    from( d in Devices.Device,
      left_join: t in assoc(d, :tags),
      where: fragment("? in (?) or ? IS NULL", t.name, splice(^tags), t.name)
    ) |> Repo.all()
  end

  def add_device(%{ token: token, description: description } = params) do
    %Devices.Device{}
    |> Devices.Device.changeset(%{
      description: description || "",
      token: token,
      tags: (params[:tags] || []) |> Tags.get_tags()
    })
    |> Repo.insert()
  end

  def list_devices() do
    Devices.Device
    |> Repo.all()
    |> Repo.preload(:tags)
  end

  def delete_device(%Devices.Device{} = device) do
    device
    |> Repo.delete()
  end

  def update_active(token) do
    get_by_token(token)
    |> Devices.Device.changeset(%{
      last_active: Timex.now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end
end
