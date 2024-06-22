defmodule MediaServerWeb.ClientController do
  use MediaServerWeb, :controller

  alias Plug.Conn
  alias MediaServer.Files
  alias MediaServer.Devices
  alias MediaServer.Actions
  alias MediaServer.Journal
  alias MediaServer.Util.RandomUtil
  alias MediaServer.Util.TimeUtil

  plug MediaServerWeb.Plugs.CheckTokenClient, [] when action in [:schedule]

  def initialize(conn, %{ "token" => token } = _params) do
    Devices.get_by_token(token)
    |> case do
      nil ->
        raise(UnauthorizedError, "Неверный токен")

      _device ->
        conn
        |> send_resp(:ok, "ok")

    end
  end

  def schedule(conn, %{ "to" => date } = params) do
    size = params["size"] || 6
    deep_select = params["deep_select"] || 10
    date = date |> TimeUtil.parse_date()

    content = Actions.list_actions_before_date(conn.assigns[:tags], date)
    |> Enum.reduce([], fn(a, acc)->
      Enum.map(a.files, fn(f)->
        %{
          action: a.name,
          priority: a.priority,
          uuid: f.uuid,
          ext: f.extention,
          filename: f.name,
          time: f.timelive_image || nil
        }
      end) ++ acc
    end)

    length_content = length(content)

    content =
      if( size < length_content) do
        limit = if(length_content - size > deep_select,
          do: deep_select, else: length_content - size)

        last_rows =
          Journal.get_rows(limit, conn.assigns[:token])
          |> Enum.map(fn(r)->r.content_uuid end)

        content
        |> Enum.filter(fn(c)->
          c.uuid not in last_rows
        end)
      else
        content
      end

    selected_content = content
      |> RandomUtil.get_num_of_rand_elems(size)

    selected_content
    |> Journal.add_rows(conn.assigns[:token])

    Devices.update_active(conn.assigns[:token])

    conn
    |> put_status(200)
    |> render("content.json", %{content: selected_content})
  end


  def content(conn, %{"uuid" => uuid, "type" => type} = _params) when type in [".png", ".jpg", ".jpeg", ".mp4"] do
    file_path = Files.file_path(uuid, type)

    if File.exists?(file_path) do
      conn
      |> send_file(200, file_path)
    else
      raise(NotFound, "Не удалось найти контент")
    end
  end

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
