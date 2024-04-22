defmodule MediaServer.Devices do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Devices

  def get_by_token(token) do
    Devices.Device
    |> Repo.get_by(token: token)
  end

  def add_device(params) do
    %Devices.Device{}
    |> Devices.Device.changeset(%{
      description: params[:descrtiption] || "",
      token: params[:token]
    })
    |> Repo.insert()
  end

  def list_devices() do
    Devices.Device
    |> Repo.all()
  end

  def delete_device(%Devices.Device{} = device) do
    device
    |> Repo.delete()
  end
end
