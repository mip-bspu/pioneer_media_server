defmodule MediaServer.Devices do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Devices
  alias MediaServer.Tags
  alias MediaServer.Users

  import Ecto.Query

  def get_by_id(id) do
    Devices.Device
    |> Repo.get_by(id: id)
    |> Repo.preload(:tags)
  end

  def get_by_token(token) do
    Devices.Device
    |> Repo.get_by(token: token)
    |> Repo.preload(:tags)
  end

  def get_devices_by_tags(tags) do
    tags = [nil | tags]

    from( d in Devices.Device,
      left_join: t in assoc(d, :tags),
      where: fragment("? in (?) or ? IS NULL", t.name, splice(^tags), t.name),
      distinct: true,
      order_by: [asc: d.description, desc: d.last_active]
    ) |> Repo.all()
  end

  def get_devices_by_role(user) do
    if Users.is_admin(user) do
      Tags.get_filtered_tags(%{list_types: ["device"]})
    else
      user
      |> Users.get_tags_of_user_by_type("device")
    end
    |> Stream.map(&(&1.name))
    |> Enum.to_list()
    |> get_devices_by_tags()
    |> Repo.preload(:tags)
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

  def delete_device(%Devices.Device{} = device) do
    device
    |> Repo.delete()
  end

  def update_device(%Devices.Device{} = device, params) do
    device
    |> Devices.Device.changeset(%{
      token: params[:token] || device.token,
      description: params[:description] || device.description,
      tags: (params[:tags] || []) |> Tags.get_tags()
    })
    |> Repo.update()
  end

  def update_active(token) do
    get_by_token(token)
    |> Devices.Device.changeset(%{
      last_active: Timex.now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end
end
