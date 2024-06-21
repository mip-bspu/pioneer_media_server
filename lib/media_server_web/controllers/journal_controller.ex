defmodule MediaServerWeb.JournalController do
  use MediaServerWeb, :controller

  alias MediaServer.Users
  alias MediaServer.Devices
  alias MediaServer.Journal
  alias MediaServer.Util.FormatUtil

  def list(conn, params) do
    user_id = conn
      |> fetch_session()
      |> get_session(:user_id)

    user = Users.get_by_id(user_id)

    page = params["page"] |> FormatUtil.to_integer() || 0
    page_size = params["page_size"] |> FormatUtil.to_integer() || 10

    {journal, count} = user.tags
      |> Stream.filter(&(&1.type == "device"))
      |> Stream.map(&(&1.name))
      |> Enum.to_list()
      |> Devices.get_devices_by_tags()
      |> Enum.map(&(&1.token))
      |> Journal.get_page_rows(page_size, page)

    IO.inspect(journal)

    conn
    |> put_status(200)
    |> render("journal.json", %{
      content: journal,
      page: page,
      page_size: page_size,
      total: count
    })
  end
end
