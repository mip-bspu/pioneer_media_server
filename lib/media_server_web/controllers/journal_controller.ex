defmodule MediaServerWeb.JournalController do
  use MediaServerWeb, :controller

  alias MediaServer.Users
  alias MediaServer.Devices
  alias MediaServer.Journal
  alias MediaServer.Util.FormatUtil

  plug MediaServerWeb.Plugs.Authentication, ["ADMIN", "USER", "VIEWER"]

  def list(conn, params) do
    user_id = conn
      |> fetch_session()
      |> get_session(:user_id)

    page = params["page"] |> FormatUtil.to_integer(0)
    page_size = params["page_size"] |> FormatUtil.to_integer(10)
    device_id = params["device_id"] |> FormatUtil.to_integer(nil)

    devices = Users.get_by_id(user_id)
      |> Devices.get_devices_by_role

    device = Enum.find(devices, &(&1.id == device_id))

    if is_nil(device) do
      raise(BadRequestError, "Устройство не найдено")
    end

    { journal, count } = [device.token]
      |> Journal.get_page_rows(page_size, page)

    conn
    |> put_status(200)
    |> render("journal.json", %{
      content: journal,
      page: page,
      page_size: page_size,
      total: count,
    })
  end
end
