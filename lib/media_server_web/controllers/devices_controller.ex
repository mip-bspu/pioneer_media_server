defmodule MediaServerWeb.DevicesController do
  use MediaServerWeb, :controller

  alias MediaServer.Devices
  alias MediaServer.Users
  alias MediaServer.Tags
  alias MediaServer.Repo

  def create(conn, %{"token" => token, "description" => description} = params \\ %{}) do
    # TODO: check tags type device
    Devices.get_by_token(token)
    |> case do
      nil ->
        Devices.add_device(%{
          description: description,
          token: token,
          tags: params["tags"] || []
        })
        |> case do
          {:ok, _device} ->
            conn
            |> put_status(200)
            |> send_resp(:ok, "ok")

          {:error, reason} ->
            raise(BadRequestError, "Некоректное значение: #{inspect(reason)}")
        end
      device ->
        raise(BadRequestError, "Устройство с таким токеном уже сущеествует")
    end
  end

  def update(conn, %{"token" => token } = params) do
    case Devices.get_by_token(token) do
      nil ->
        raise(BadRequestError, "Не правильный токен")

      device ->
        Devices.update_device(device, %{
          token: params["new_token"],
          description: params["description"],
          tags: params["tags"]
        })
        |> case do
          {:ok, _device} ->
            conn
            |> put_status(200)
            |> send_resp(:ok, "ok")

          {:error, reason} ->
            raise(BadRequestError, "Некоректное значение: #{inspect(reason)}")
        end
    end
  end

  def delete(conn, %{"token" => token} = params \\ %{}) do
    case Devices.get_by_token(token) do
      nil ->
        raise(BadRequestError, "Не правильный токен")

      device->
        Devices.delete_device(device)
        |> case do
          {:ok, device} ->
            conn
            |> put_status(200)
            |> send_resp(:ok, "ok")

          {:error, reason}->
            raise(InternalServerError, "Не удалось удалить")
        end
    end
  end

  def list(conn, _params) do
    user_id = conn
      |> fetch_session()
      |> get_session(:user_id)

    devices =
      Users.get_by_id(user_id)
      |> get_devices_by_role

    conn
    |> put_status(200)
    |> render("devices.json", %{devices: devices})
  end

  def min_list(conn, _params) do
    user_id = conn
      |> fetch_session()
      |> get_session(:user_id)

    devices =
      Users.get_by_id(user_id)
      |> get_devices_by_role

    conn
    |> put_status(200)
    |> render("min_devices.json", %{devices: devices})
  end

  defp get_devices_by_role(user) do
    if Users.is_admin(user) do
      Tags.get_filtered_tags(%{list_types: ["device"]})
    else
      user
      |> Users.get_tags_of_user_by_type("device")
    end
    |> Stream.map(&(&1.name))
    |> Enum.to_list()
    |> Devices.get_devices_by_tags()
    |> Repo.preload(:tags)
  end
end
