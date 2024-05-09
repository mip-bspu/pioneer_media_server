defmodule MediaServerWeb.DevicesController do
  use MediaServerWeb, :controller

  alias MediaServer.Devices

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
    conn
    |> put_status(200)
    |> render("devices.json", %{devices: Devices.list_devices()})
  end
end
