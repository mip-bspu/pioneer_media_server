defmodule MediaServerWeb.ClientController do
  use MediaServerWeb, :controller

  alias Plug.Conn
  alias MediaServer.Files
  alias MediaServer.Devices
  alias MediaServer.Actions
  alias MediaServer.Journal
  alias MediaServerWeb.ErrorView

  plug MediaServerWeb.Plugs.CheckTokenClient, [] when action in [:schedule]

  def initialize(conn, %{ "token" => token } = _params) do
    Devices.get_by_token(token)
    |> case do
      nil ->
        conn
        |> put_status(401)
        |> put_view(ErrorView)
        |> render("unauthorized.json", %{message: "Неверный токен"})
        |> halt()
      _device ->

        conn
        |> put_status(200)
        |> json(%{message: "ok"})
    end
  end

  def schedule(conn, params) do


  def content(conn, %{"uuid" => uuid, "type" => type} = _params) when type in [".mp4"] do
    file_path = Files.file_path(uuid, type)

    if File.exists?(file_path) do
      if !Enum.empty?(Conn.get_req_header(conn, "range")) do
        stats = File.stat!(file_path)
        file_size = stats.size

        conn
        |> put_resp_header("Content-Type", "video/mp4")
        |> put_resp_header("Accept-Ranges", "bytes")
        |> put_resp_header("Content-Range", "bytes #{0}-#{file_size-1}/#{file_size}")
        |> send_file(206, file_path)
      else
        conn
        |> send_file(200, file_path)
      end
    else
      raise(NotFound, "Не удалось найти контент")
    end
  end
end
