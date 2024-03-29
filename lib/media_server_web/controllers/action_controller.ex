defmodule MediaServerWeb.ActionController do
  use MediaServerWeb, :controller

  alias MediaServer.Actions
  alias MediaServer.Files
  alias MediaServer.Util.FormatUtil

  def create(conn, params \\ %{}) do
    Actions.add_action(%{
      name: params["name"],
      from: params["from"],
      to: params["to"],
      priority: (params["priority"] || 0) |> FormatUtil.to_integer(),
      tags: params["tags"]
    })
    |> case do
      {:ok, action} ->
        Enum.each(params["files"] || [], fn file ->
          Files.add_file!(file, action.id)
        end)

        # TODO: проверка области доступа

        conn
        |> put_status(:ok)
        |> render("action.json", %{
          action: Actions.get_by_uuid(action.uuid)
        })

      {:error, reason} ->
        raise(BadRequestError, "Неверные данные: #{reason}")
    end
  end
end
