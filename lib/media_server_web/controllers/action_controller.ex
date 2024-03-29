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

  def list(conn, params \\ %{}) do
    page = Access.get(params, "page", 0) |> FormatUtil.to_integer()
    page_size = Access.get(params, "page_size", 10) |> FormatUtil.to_integer()

    tags =
      Access.get(params, "tags", "")
      |> String.split([",", ", "], trim: true)

    {total, actions} = Actions.list_actions(tags, page, page_size)

    conn
    |> put_status(:ok)
    |> render("actions.json", %{
      actions: %{
        actions: actions,
        total_items: total,
        page: page,
        page_size: page_size
      }
    })
  end
end
