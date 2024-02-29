defmodule MediaServerWeb.AMQP.FilesSyncService do
  require Logger
  use GenServer
  use AMQP

  alias MediaServerWeb.Rpc.RpcClient
  alias MediaServer.Content
  alias MediaServer.Util.TimeUtil

  @name __MODULE__
  @check_interval 10 * 1000

  @parent Application.compile_env(:media_server, :queue_parent)
  @my_tag Application.compile_env(:media_server, :queue_tag)

  def start_link(_state \\ []) do
    GenServer.start_link(@name, [], name: @name)
  end

  def init(_opts) do
    Logger.info("#{@name}: starting files sync service")

    Process.send_after(@name, :check_content, @check_interval)
    {:ok, :state}
  end

  def request_tags() do
    {:ok, tags} = Content.get_all_my_tags()
    Enum.map(tags, fn tag -> tag["name"] end)
  end

  def handle_info(:check_content, state) do
    spawn(fn ->
      with {:ok, remote_state} <- RpcClient.months_state(@parent, request_tags()),
           {:ok, local_state} <- Content.months_state(request_tags()) do
        diff = remote_state -- local_state
        Logger.debug("#{@name}: Discovered difference months: #{inspect(diff)}")

        if diff != [] do
          send(@name, {:check_months, diff, @parent})
        end
      else
        error -> Logger.warning("#{@name}: Error check_content in reason: #{inspect(error)}")
      end
    end)

    Process.send_after(@name, :check_content, @check_interval)
    {:noreply, state}
  end

  def handle_info({:check_months, months, tag}, state) do
    months
    |> Enum.each(fn month ->
      spawn(fn ->
        with {:ok, remote_state} <-
               RpcClient.days_of_month_state(tag, request_tags(), month[:label]),
             {:ok, local_state} <- Content.days_of_month_state(request_tags(), month[:label]) do
          diff = remote_state -- local_state
          Logger.debug("#{@name}: Discovered difference days of month: #{inspect(diff)}")

          if diff != [] do
            send(@name, {:check_days, diff, tag})
          end
        else
          error -> Logger.warning("#{@name}: Error check_months in reason: #{inspect(error)}")
        end
      end)
    end)

    {:noreply, state}
  end

  def handle_info({:check_days, days, tag}, state) do
    days
    |> Enum.each(fn day ->
      spawn(fn ->
        with {:ok, remote_state} <- RpcClient.rows_of_day_state(tag, request_tags(), day[:label]),
             {:ok, local_state} <- Content.rows_of_day_state(request_tags(), day[:label]) do
          diff = remote_state -- local_state
          Logger.debug("#{@name}: Discovered difference rows of day: #{inspect(diff)}")

          if diff != [] do
            send(@name, {:check_rows, diff, tag})
          end
        else
          error -> Logger.warning("#{@name}: Error check_days in reason: #{inspect(error)}")
        end
      end)
    end)

    {:noreply, state}
  end

  def handle_info({:check_rows, rows, tag}, state) do
    rows
    |> Enum.each(fn row ->
      spawn(fn ->
        with {:ok, remote_file} <- RpcClient.get_by_uuid(tag, row[:label]),
             remote_file <- %{
               remote_file
               | date_create: TimeUtil.from_iso_to_date!(remote_file[:date_create])
             } do
          case Content.get_by_uuid(row[:label]) do
            nil ->
              Logger.debug("#{@name}: The file does not exist: #{inspect(remote_file)}")

              Content.add_file_data!(remote_file)

              RpcClient.request_file_download(tag, @my_tag, remote_file[:uuid])

            file ->
              Logger.debug("#{@name}: The file exist")

              if Content.parse_content(file) != remote_file do
                Logger.debug("#{@name}: Is data changes")
                Content.update_file_data!(file, remote_file)
              end

              if file.check_sum != remote_file[:check_sum] do
                Logger.debug("#{@name}: Isn't equals check_sums")
                RpcClient.request_file_download(tag, @my_tag, remote_file[:uuid])
              end
          end
        else
          e ->
            Logger.warning("#{@name}: Error check_rows in reason #{inspect(e)}")
        end
      end)
    end)

    {:noreply, state}
  end
end
