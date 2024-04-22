defmodule MediaServer.Devices.DeviceTags do
  use Ecto.Schema

  alias MediaServer.Devices
  alias MediaServer.Tags

  schema "device_tags" do
    belongs_to :device, Devices.Device
    belongs_to :tag, Tags.Tag
  end
end
