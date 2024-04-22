defmodule MediaServer.Devices do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Devices
  alias MediaServer.Tags

  def get_by_token(token) do
    Devices.Device
    |> Repo.get_by(token: token)
    |> Repo.preload(:tags)
  end

  def add_device(%{ token: token } = params) do
    %Devices.Device{}
    |> Devices.Device.changeset(%{
      description: params[:descrtiption] || "",
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
end
