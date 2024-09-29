defmodule MediaServer.Journal do
  require Logger

  alias MediaServer.Repo
  alias MediaServer.Journal.Journal
  alias MediaServer.Util.TimeUtil

  import Ecto.Query

  def add_rows(list_rows, token) do
    new_list_rows = list_rows
      |> Enum.map(fn(row)->
        params = %{
            action: row[:action],
            content_uuid: row[:content_uuid] || row[:uuid],
            ext: row[:ext],
            filename: row[:filename],
            priority: row[:priority],
            inserted_at: Timex.now() |> DateTime.truncate(:second),
            updated_at: Timex.now() |> DateTime.truncate(:second),
            token: token
          }
      end)

    Repo.insert_all(Journal, new_list_rows)
  end

  def get_rows(limit, token) do
    from( j in Journal,
      where: j.token == ^token,
      order_by: [desc: j.inserted_at, desc: j.id],
      limit: ^limit
    )
    |> Repo.all()
  end

  def get_page_rows(tokens, size, page) do
    query = from( j in Journal,
        where: fragment("? in (?)", j.token, splice(^tokens))
      )

    journal = query
      |> order_by([j], desc: j.inserted_at)
      |> limit([_], ^size)
      |> offset([_], ^(size*page))
      |> Repo.all()

    count = query |> select([j], count(j)) |> Repo.one()

    {journal, count}
  end

  def delete_rows_before_date(date) do
    from(j in Journal, where: fragment("?::DATE < ?", j.inserted_at, ^date))
    |> Repo.delete_all()
  end
end
