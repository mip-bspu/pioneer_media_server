defmodule MediaServerWeb.ActionController do
  use MediaServerWeb, :controller

  alias MediaServer.Actions
  alias MediaServer.Files
  alias MediaServer.Users
  alias MediaServer.Util.FormatUtil
  alias MediaServer.Util.TimeUtil

  @image_formats Application.compile_env(:media_server, :image_formats)
  @video_formats Application.compile_env(:media_server, :video_formats)

  def create(conn, params \\ %{}) do
    if is_list(params["tags"]) do
      user = conn
          |> fetch_session()
          |> get_session(:user_id)
          |> Users.get_by_id()

      tags = params["tags"] -- Enum.map(user.tags, &(&1.name))

      if length(tags) > 0 do
        raise( BadRequestError, "Не допустимые тэги" )
      end
    end

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
          ext = Path.extname(file.filename)

          if ext in @image_formats || ext in @video_formats do
            time = times |> Enum.find(fn(t)->file.filename == hd t end)

            Files.add_file!(
              file,
              action.id,
              if(time, do: time |> Enum.at(1) |> FormatUtil.to_integer(), else: nil)
            )
          end
        end)

        conn
        |> put_status(:ok)
        |> render("action.json", %{
          action: action.uuid |> Actions.get_by_uuid()
        })

      {:error, _reason} ->
        raise( BadRequestError, "Неверные данные" )

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

  defp if_exists(nil), do: raise(BadRequestError, "Такого события не существует")
  defp if_exists(item), do: item
end
