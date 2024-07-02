defmodule MediaServerWeb.DevicesView do
  use MediaServerWeb, :view

  alias MediaServerWeb.TagsView

  def render("devices.json", %{devices: devices}), do: normalize_devices(devices)
  def render("min_devices.json", %{devices: devices}), do: normalize_min_devices(devices)

  def normalize_min_devices(devices), do:
      devices |> Enum.map(fn device -> %{
        id: device.id,
        description: device.description
      }
    end)

  def normalize_devices(devices),
  do:
    devices
    |> Enum.map(fn device ->
      %{
        id: device.id,
        description: device.description,
        token: device.token,
        tags: TagsView.normalize_tags(device.tags),
        last_active: device.last_active
      }
    end)
end
