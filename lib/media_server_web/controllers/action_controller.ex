defmodule MediaServerWeb.ActionController do
  use MediaServerWeb, :controller

  alias MediaServer.Actions
  alias MediaServer.Files
  alias MediaServer.Util.FormatUtil
  alias MediaServer.Util.TimeUtil

  def create(conn, params \\ %{}) do
    Actions.add_action(%{
      name: params["name"],
      from: params["from"] |> TimeUtil.parse_date(),
      to: params["to"] |> TimeUtil.parse_date(),
      priority: (params["priority"] || 0) |> FormatUtil.to_integer(),
      tags: params["tags"]
    })
    |> case do
      {:ok, action} ->
        times = params["times"] && params["times"] |> Enum.map(fn(img)-> img |> String.split(";") end) || []

        Enum.each(params["files"] || [], fn file ->
          time = times |> Enum.find(fn(t)->file.filename == hd t end)

          Files.add_file!(
            file,
            action.id,
            if(time, do: time |> Enum.at(1) |> FormatUtil.to_integer(), else: nil)
          )
        end)

        # TODO: проверка области доступа
        conn
        |> put_status(:ok)
        |> render("action.json", %{
          action: action.uuid |> Actions.get_by_uuid()
        })

      {:error, reason} ->
        raise(BadRequestError, "Неверные данные: #{reason}")
    end
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

  def update(conn, %{"uuid" => uuid} = params) do
    uuid
    |> Actions.get_by_uuid()
    |> if_exists()
    |> Actions.update_action(%{
      name: params["name"],
      from: params["from"],
      to: params["to"],
      priority: params["priority"] && params["priority"] |> FormatUtil.to_integer(),
      tags: params["tags"]
    })
    |> case do
      {:ok, action} ->
        conn
        |> put_status(:ok)
        |> render("action.json", %{
          action: action.uuid |> Actions.get_by_uuid()
        })

      {:error, reason} ->
        raise(BadRequestError, "Неверные данные: #{reason}")
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

  defp if_exists(nil), do: raise(BadRequestError, "Такого события не существует")
  defp if_exists(item), do: item
end
