defmodule MediaServer.Journal do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Journal.Journal
  alias MediaServer.Util.TimeUtil

  import Ecto.Query

  def add_rows(list_rows) do
    new_list_rows = list_rows
      |> Enum.map(fn(row)->
        %{
          action: row[:action],
          content_uuid: row[:content_uuid] || row[:uuid],
          priority: row[:priority],
          inserted_at: Timex.now() |> DateTime.truncate(:second),
          updated_at: Timex.now() |> DateTime.truncate(:second)
        }
      end)

    Repo.insert_all(Journal, new_list_rows)
  end

  def get_rows(limit) do
    from( j in Journal, order_by: [desc: j.inserted_at, desc: j.id], limit: ^limit)
    |> Repo.all()
  end
end
