defmodule MediaServerWeb.AMQP.FilesSyncService do
  require Logger
  use GenServer
  use AMQP

  alias MediaServerWeb.Rpc.RpcClient
  alias MediaServer.Content

  @name __MODULE__
  @check_interval 1000

  @parents Application.compile_env(:media_server, :parents)
  @my_tag Application.compile_env(:media_server, :tag)

  @request_tags [@my_tag]++@parents

  def start_link(_state \\ []) do
    GenServer.start_link(@name, [], name: @name)
  end

  def init(_opts) do
    Logger.info("#{@name}: starting files sync service")

    Process.send_after(@name, :check_content, @check_interval)
    {:ok, :state}
  end

  def handle_info(:check_content, state) do
    @parents
    |> Enum.each(fn tag ->
      spawn(fn ->
        {:ok, remote_state} = RpcClient.months_state(tag, @request_tags) # TODO: tags children
        {:ok, local_state} = Content.months_state(@request_tags) # TODO: exception

        diff = remote_state -- local_state
        Logger.debug("#{@name}: Discovered difference months: #{inspect(diff)}")

        if diff != [] do
          send(@name, {:check_months, diff, tag})
        end
      end)
    end)

    {:noreply, state}
  end

  def handle_info({:check_months, months, tag}, state) do
    IO.puts("yes check months")
    months
    |> Enum.each(fn(month)->
      spawn(fn->
        {:ok, remote_state} = RpcClient.days_of_month_state(tag, @request_tags, month[:label])
        {:ok, local_state} = Content.days_of_month_state(@request_tags, month[:label])

        diff = remote_state -- local_state
        Logger.debug("#{@name}: Discovered difference days of month: #{inspect(diff)}")

        if diff != [] do
          send(@name, {:check_days, diff, tag})
        end
      end)
    end)

    {:noreply, state}
  end

  def handle_info({:check_days, days, tag}, state) do
    days
    |> Enum.each(fn(day)->
      spawn(fn->
        {:ok, remote_state} = RpcClient.rows_of_day_state(tag, @request_tags, day[:label])
        {:ok, local_state} = Content.rows_of_day_state(@request_tags, day[:label])

        diff = remote_state -- local_state
        Logger.debug("#{@name}: Discovered difference rows of day: #{inspect(diff)}")

        if diff != [] do
          send(@name, {:check_rows, diff, tag})
        end
      end)
    end)

    {:noreply, state}
  end

  def handle_info({:check_rows, rows, tag}, state) do
    IO.puts("yes check_rows")

    rows
    |> Enum.each(fn(row)->
      spawn(fn->
        {:ok, remote_file} = RpcClient.get_by_uuid(tag, row[:label])

        case Content.get_by_uuid(row[:label]) do
          nil->
            IO.puts("empty")
            IO.inspect(remote_file)

            RpcClient.request_file_download(tag, @my_tag, remote_file[:uuid])

          file->
            IO.inspect(file)
        end
      end)
    end)

    {:noreply, state}
  end
end
