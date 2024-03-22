defmodule MediaServerWeb.ActionController do
  use MediaServerWeb, :controller

  alias MediaServer.Actions
  alias MediaServer.Files
  alias MediaServer.Tags
  alias MediaServer.Repo
  alias MediaServer.Util.FormatUtil
  alias MediaServer.Util.TimeUtil

  def create(conn, params \\ %{}) do
    if Repo.get_by(Actions.Action, name: params["name"]) do
      raise(BadRequestError, "Событие с таким именем уже существует")
    end

    Actions.add_action!(%{
      name: params["name"],
      from: params["from"],
      to: params["to"],
      to: TimeUtil.current_date_time(),
      priority: (params["priority"] || 0) |> FormatUtil.to_integer(),
      tags: Tags.get_filtered_tags(%{list_tags: params["tags"] || :none})
    })
    |> case do
      {:ok, action} ->
        Enum.each(params["files"] || [], fn file ->
          Files.add_file!(file, action.id)
        end)

        action =
          Repo.get_by(Actions.Action, id: action.id)
          |> Repo.preload(:tags)
          |> Repo.preload(:files)

        conn
        |> put_status(:ok)
        |> render("action.json", %{action: action})

      _error ->
        raise(BadRequestError, "Неверные данные")
    end
  end
end
