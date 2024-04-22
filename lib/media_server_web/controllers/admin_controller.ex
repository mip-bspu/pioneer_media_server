defmodule MediaServerWeb.AdminController do
  use MediaServerWeb, :controller

  alias MediaServer.Admin
  alias MediaServer.Users
  alias MediaServer.Devices
  alias MediaServerWeb.ErrorView

  plug MediaServerWeb.Plugs.Authentication, ["ADMIN"]

  def list_users(conn, _params \\ %{}) do
    conn
    |> put_status(200)
    |> render("users.json", %{users: Admin.get_users()})
  end

  def list_groups(conn, _params) do
    conn
    |> put_status(200)
    |> render("groups.json", %{groups: Admin.get_groups()})
  end

  def update_user(conn, %{"id" => user_id} = params \\ %{}) do
    user_id
    |> Users.get_by_id()
    |> Users.update_user(%{
      tags: params["tags"],
      groups: params["groups"]
    })
    |> case do
      {:ok, user} ->
        conn
        |> put_status(200)
        |> render("user.json", %{user: user})

      {:error, reason} ->
        raise(BadRequestError, "Не удалось обновить данные: #{reason}")
    end
  end

  def create_user(conn, %{"login" => login, "password" => password, "groups" => groups} = params) do
    Users.get_by_login(login)
    |> case do
      nil ->
        Users.add_user(%{
          login: login,
          password: password,
          groups: groups,
          tags: params["tags"] || []
        })
        |> case do
          {:ok, user} ->
            conn
            |> put_status(200)
            |> render("user.json", %{user: user})

          {:error, reason} ->
            raise(BadRequestError, "Некоректное значение #{reason}")
        end

      _user ->
        conn
        |> put_status(400)
        |> put_view(ErrorView)
        |> render("bad_request.json", %{message: "Пользователь с таким логином уже существует"})
        |> halt()
    end
  end

  def set_active(conn, %{"active" => val, "id" => user_id} = _params) do
    user_id = user_id |> String.to_integer()

    value =
      cond do
        val in ["0", "false", false] -> false
        val in ["1", "true", true] -> true
        true -> raise(BadRequestError, "Некоректное значение")
      end

    try do
      conn
      |> put_status(200)
      |> render("user.json", %{
        user: Admin.set_active_user!(user_id, value)
      })
    rescue
      reason -> raise(BadRequestError, "Некоректное значение: #{reason}")
    end
  end

  def create_device(conn, %{"token" => token} = params \\ %{}) do
    Devices.get_by_token(token)
    |> case do
      nil ->
        Devices.add_device(%{
          description: params[:description],
          token: token
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

  def delete_device(conn, %{"token" => token} = params \\ %{}) do
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

  def list_devices(conn, _params \\ %{}) do
    conn
    |> put_status(200)
    |> render("devices.json", %{devices: Devices.list_devices()})
  end
end
