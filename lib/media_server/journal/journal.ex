defmodule MediaServer.Journal do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Journal.Journal
  alias MediaServer.Util.TimeUtil

  import Ecto.Query

  def add_rows(list_rows, token) do
    new_list_rows = list_rows
      |> Enum.map(fn(row)->
        %{
          action: row[:action],
          content_uuid: row[:content_uuid] || row[:uuid],
          priority: row[:priority],
          inserted_at: Timex.now() |> DateTime.truncate(:second),
          updated_at: Timex.now() |> DateTime.truncate(:second),
          token: token,
        }
      end)

    Repo.insert_all(Journal, new_list_rows)
  end

  def get_rows(limit, token) do
    from( j in Journal, where: j.token == ^token, order_by: [desc: j.inserted_at, desc: j.id], limit: ^limit)
    |> Repo.all()
  end
end
