defmodule MediaServer.Util.QueryUtil do
  require Logger

  alias MediaServer.Repo

  def query_select(query, params) do
    case Ecto.Adapters.SQL.query(Repo, query, params) do
      {:ok, %Postgrex.Result{command: :select, columns: cols, rows: rows}} ->
        {:ok, decode_table(cols, rows)}
      error ->
        Logger.error("Error execute query: #{inspect(error)}")
        {:bad_request, "Ошибка выполнения запроса"}
    end
  end

  defp decode_table(cols, rows), do: decode_table(cols, rows, [])
  defp decode_table(_, [], result), do: result

  defp decode_table(cols, [row | rows], result),
    do: decode_table(cols, rows, result ++ [line_decoder(cols, row, %{})])

  defp line_decoder([], [], map), do: map

  defp line_decoder([col | tcol], [val | row], map),
    do: line_decoder(tcol, row, Map.put(map, col, val))
end
