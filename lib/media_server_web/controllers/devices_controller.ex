defmodule MediaServerWeb.DevicesController do
  use MediaServerWeb, :controller

  alias MediaServer.Devices
  alias MediaServer.Users
  alias MediaServer.Tags
  alias MediaServer.Repo

  plug MediaServerWeb.Plugs.Authentication, ["ADMIN"] when action in [:create, :update, :delete]
  plug MediaServerWeb.Plugs.Authentication, ["ADMIN", "USER", "VIEWER"] when action in [:list, :min_list]

  def create(conn, %{"token" => token, "description" => description} = params \\ %{}) do
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

  def update(conn, %{"id" => id} = params) do
    case Devices.get_by_id(id) do
      nil ->
        raise(BadRequestError, "Устройство не найдено")

      device ->
        Devices.update_device(device, %{
          token: params["token"],
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

  def delete(conn, %{"id" => id} = params \\ %{}) do
    case Devices.get_by_id(id) do
      nil ->
        raise(BadRequestError, "Устройство не найдено")

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
      |> Devices.get_devices_by_role

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
      |> Devices.get_devices_by_role

    conn
    |> put_status(200)
    |> render("min_devices.json", %{devices: devices})
  end
end
