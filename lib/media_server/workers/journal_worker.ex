defmodule MediaServer.Workers.JournalWorker do
  require Logger
  use GenServer

  alias MediaServer.Journal
  alias MediaServer.Util.TimeUtil

  @name __MODULE__

  @interval_clear_journal 3 * 60 * 1000
  @days_for_storage 60

  def start_link(state), do: GenServer.start_link(@name, state, name: @name)

  def init(state) do
    Logger.info("#{@name}: starting journal_worker")

    Process.send_after(@name, :clear, @interval_clear_journal)
    {:ok, state}
  end


  def handle_info(:clear, state) do
    spawn(fn->
      TimeUtil.get_date_shift_days( -@days_for_storage )
      |> Journal.delete_rows_before_date()
    end)

    Process.send_after(@name, :clear, @interval_clear_journal)

    {:noreply, state}
  end
end
