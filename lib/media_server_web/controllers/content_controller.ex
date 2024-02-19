defmodule MediaServerWeb.ContentController do
  use MediaServerWeb, :controller

  alias MediaServer.Content

  def create(conn, %{"name"=>name, "file"=>%Plug.Upload{} = upload}) do
    IO.puts("create")

    Content.add_file!(name, upload)


    conn
    |> send_resp(200, "yes")
  end
end
