defmodule MediaServerWeb.DevicesView do
  use MediaServerWeb, :view

  alias MediaServerWeb.TagsView

  def render("devices.json", %{devices: devices}), do: normilize_devices(devices)

  def normilize_devices(devices),
  do:
    devices
    |> Enum.map(fn device ->
      %{
        description: device.description,
        token: device.token,
        tags: TagsView.normilize_tags(device.tags),
      }
    end)
end
