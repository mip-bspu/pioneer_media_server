defmodule MediaServerWeb.DevicesView do
  use MediaServerWeb, :view

  alias MediaServerWeb.TagsView

  def render("devices.json", %{devices: devices}), do: normalize_devices(devices)

  def normalize_devices(devices),
  do:
    devices
    |> Enum.map(fn device ->
      %{
        description: device.description,
        token: device.token,
        tags: TagsView.normalize_tags(device.tags),
      }
    end)
end
