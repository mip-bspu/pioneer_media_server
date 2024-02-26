defmodule MediaServerWeb.ContentController do
  use MediaServerWeb, :controller

  alias MediaServer.Content

  def create(conn, %{"name"=>name,"tags"=>tags, "file"=>%Plug.Upload{} = upload}) do
    tags = String.split(tags, [", ", ","], trim: true)

    Content.add_file!(name, upload, tags)
    conn
    |> send_resp(200, "yes")
  end
end
