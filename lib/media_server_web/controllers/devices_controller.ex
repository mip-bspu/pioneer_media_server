defmodule MediaServerWeb.DevicesController do
  use MediaServerWeb, :controller

  alias MediaServer.Devices
  alias MediaServer.Users
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
            raise(BadRequestError, "Некоректное значение: #{reason}")
        end
      device ->
        raise(BadRequestError, "Устройство с таким токеном уже сущеествует")
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

  def list(conn, _params \\ %{}) do
    user_id = conn
      |> fetch_session()
      |> get_session(:user_id)

    devices = Users.get_by_id(user_id)
      |> Users.get_tags_of_user_by_type("device")
      |> Devices.get_devices_by_tags()
      |> Repo.preload(:tags)

    conn
    |> put_status(200)
    |> render("devices.json", %{devices: devices})
  end
end
