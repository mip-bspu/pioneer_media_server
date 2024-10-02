defmodule MediaServerWeb.ActionController do
  use MediaServerWeb, :controller

  alias MediaServer.Actions
  alias MediaServer.Files
  alias MediaServer.Users
  alias MediaServer.Tags
  alias MediaServer.Util.FormatUtil
  alias MediaServer.Util.TimeUtil

  plug MediaServerWeb.Plugs.Authentication, ["ADMIN", "USER", "VIEWER"] when action in [:list, :list_from_period]
  plug MediaServerWeb.Plugs.Authentication, ["ADMIN", "USER"] when action in [:create, :update, :delete, :update_files_data]

  def create(conn, params \\ %{}) do
    user = conn
      |> fetch_session()
      |> get_session(:user_id)
      |> Users.get_by_id()

    tags = Tags.check_correct_tags(user, params["tags"])

    Actions.add_action(%{
      name: params["name"],
      from: params["from"] |> TimeUtil.parse_date(),
      to: params["to"] |> TimeUtil.parse_date(),
      priority: params["priority"] |> FormatUtil.to_integer(1),
      tags: tags
    })
    |> case do
      {:ok, action} ->
        times = params["times"] && params["times"] |> Enum.map(fn(img)-> img |> String.split(";") end) || []

        Files.add_files!(action, params["files"], times)

        conn
        |> put_status(:ok)
        |> render("action.json", %{
          action: action.uuid |> Actions.get_by_uuid()
        })

      {:error, _reason} ->
        raise( BadRequestError, "Неверные данные" )

    end
  end

  def update(conn, %{"uuid" => uuid} = params) do
    user = conn
      |> fetch_session()
      |> get_session(:user_id)
      |> Users.get_by_id()

    tags = Tags.check_correct_tags(user, params["tags"])

    uuid
    |> Actions.get_by_uuid()
    |> if_exists()
    |> Actions.update_action(%{
      name: params["name"],
      from: params["from"],
      to: params["to"],
      priority: params["priority"] && params["priority"] |> FormatUtil.to_integer(1),
      tags: tags
    })
    |> case do
      {:ok, action} ->
        Files.add_files!(action, params["append_files"])

        if is_list(params["delete_files"]) && length(params["delete_files"]) > 0 do
          Files.delete_files!(action, params["delete_files"])
        end

        conn
        |> put_status(:ok)
        |> render("action.json", %{
          action: action.uuid |> Actions.get_by_uuid()
        })

      {:error, _reason} ->
        raise(BadRequestError, "Неверные данные")
    end
  end

  def delete(conn, %{"uuid" => uuid} = _params) do
    try do
      action = Actions.delete_by_uuid!(uuid)

      conn
      |> put_status(200)
      |> render("action.json", %{
        action: action
      })
    rescue
      _e ->
        raise(BadRequestError, "Такого события не существует")
    end
  end

  def update_files_data(conn, %{ "uuid" => uuid } = params) do
    action = uuid
      |> Actions.get_by_uuid()
      |> if_exists()

    times = (params["times"] || []) |> Enum.map(&(%{uuid: &1["uuid"], time: &1["time"]}))
    Files.update_files!(action, %{ times: times })

    conn
    |> put_status(:ok)
    |> render("action.json", %{
      action: action.uuid |> Actions.get_by_uuid()
    })
  end

  def list_from_period(conn, params \\ %{}) do
    tags = Access.get(params, "tags", "") |> String.split([",", ", "])
    from = Access.get(params, "from") |> TimeUtil.parse_date()
    to = Access.get(params, "to") |> TimeUtil.parse_date()

    [from, to] = if(Timex.compare(to, from) < 0, do: [to, from], else: [from, to])

    conn
    |> put_status(:ok)
    |> render("actions.json", %{
      range_actions: Actions.list_actions_from_period(tags, from, to)
    })
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

  defp if_exists(nil), do: raise(BadRequestError, "Такого события не существует")
  defp if_exists(item), do: item
end
