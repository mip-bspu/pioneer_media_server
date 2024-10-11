defmodule MediaServerWeb.AMQP.FilesSyncService do
  require Logger
  use GenServer
  use AMQP

  alias MediaServerWeb.Rpc.RpcClient
  alias MediaServerWeb.AMQP.FilesSyncDownloader
  alias MediaServer.Actions
  alias MediaServer.Files
  alias MediaServer.Tags
  alias MediaServer.Util.FormatUtil

  @name __MODULE__
  @check_interval Application.get_env(:media_server, :interval_sync_check)

  @parent Application.get_env(:media_server, :queue_parent)

  def start_link(_state \\ []) do
    GenServer.start_link(@name, [], name: @name)
  end

  def init(_opts) do
    Logger.info("#{@name}: starting files sync service")

    send(@name, :check_content)
    # Process.send_after(@name, :check_content, @check_interval)
    {:ok, :state}
  end

  defp request_tags() do
    Tags.get_all_my_tags()
    |> Enum.map(fn tag -> tag.name end)
  end

  defp get_diff_remove(local_states, remote_states, field \\ :label) do
    (local_states -- remote_states)
    |> Enum.filter(fn lstate ->
      Enum.find(remote_states, fn rstate ->
        get_in(rstate, [Access.key!(field)]) == get_in(lstate, [Access.key!(field)])
      end) == nil
    end)
  end

  def handle_info(:check_content, state) do
    spawn(fn ->
      with {:ok, remote_state} <- RpcClient.months_state(@parent, request_tags()),
           {:ok, local_state} <- Actions.months_state(request_tags()),
           local_state <- FormatUtil.to_maps_key_atom(local_state) do
        diff_add = remote_state -- local_state
        diff_remove = get_diff_remove(local_state, remote_state)

        diff = diff_add ++ diff_remove

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
             {:ok, local_state} <- Actions.days_of_month_state(request_tags(), month[:label]),
             local_state <- FormatUtil.to_maps_key_atom(local_state) do
          diff_add = remote_state -- local_state
          diff_remove = get_diff_remove(local_state, remote_state)

          diff = diff_add ++ diff_remove

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
             {:ok, local_state} <- Actions.rows_of_day_state(request_tags(), day[:label]),
             local_state <- FormatUtil.to_maps_key_atom(local_state) do
          diff_add = remote_state -- local_state
          diff_remove = get_diff_remove(local_state, remote_state)

          diff = diff_add ++ diff_remove

          Logger.debug("#{@name}: Discovered difference rows of day: #{inspect(diff)}")

          if diff_remove != [] do
            send(@name, {:remove_rows, diff_remove})
          end

          if diff_add != [] do
            send(@name, {:check_rows, diff_add, tag})
          end
        else
          error -> Logger.warning("#{@name}: Error check_days in reason: #{inspect(error)}")
        end
      end)
    end)

    {:noreply, state}
  end

  def handle_info({:remove_rows, rows}, state) do
    Logger.debug("#{@name}: is rows for delete")

    rows
    |> Enum.each(fn row ->
      spawn(fn ->
        with action <- Actions.get_by_uuid(row[:label]) do
          try do
            if FilesSyncDownloader.get_state_download(action.uuid) == :none do
              Logger.debug("#{@name}: deleting action #{action.name}...")
              Actions.delete_by_uuid!(action.uuid)
            end
          rescue
            e ->
              Logger.error("#{@name}: Error remove_rows in delete_by_uuid: #{inspect(e)}")
          end
        else
          e -> Logger.warning("#{@name}: Error remove_rows in reason #{inspect(e)}")
        end
      end)
    end)

    {:noreply, state}
  end

  def handle_info({:check_rows, rows, tag}, state) do
    rows
    |> Enum.each(fn row ->
      spawn(fn ->
        with {:ok, %{tags: tags} = remote_action} <- RpcClient.get_by_uuid(tag, row[:label]),
             remote_action <- %{
               remote_action
               | tags: tags |> Enum.filter(&(&1[:type] != "node"))
             } do
          case Actions.get_by_uuid(row[:label]) do
            nil ->
              Logger.debug("#{@name}: The action does not exist: #{inspect(remote_action)}")

              Actions.add_action(%{
                remote_action
                | tags: Enum.map(remote_action[:tags], fn action_tag -> action_tag.name end)
              })
              |> case do
                {:ok, action} ->
                  Enum.each(remote_action[:files], fn data_file ->
                    data_file
                    |> Map.put(:action_id, action.id)
                    |> Files.add_file_data!()
                  end)

                  FilesSyncDownloader.request_download(tag, remote_action[:files], action.uuid)

                {:error, reason} ->
                  Logger.error(
                    "#{@name}: Error add action #{inspect(remote_action)} in reason: #{inspect(reason)}"
                  )
              end

            action ->
              state_download = FilesSyncDownloader.get_state_download(action.uuid)

              Logger.debug(
                "#{@name}: The action exist #{action.name}, state download: #{state_download}"
              )

              if state_download == :none do
                Actions.update_action(action, remote_action)

                if Files.normalize_files(action.files) !=
                     Files.normalize_files(remote_action.files) do
                  Logger.warning("#{@name}: between files is difference")

                  delete_files = get_diff_remove(action.files, remote_action.files, :uuid)
                  add_files = remote_action.files -- action.files

                  if delete_files != [] do
                    Logger.debug("#{@name}: exists files for deleting #{inspect(delete_files)}")
                    Files.delete_files!(delete_files)
                  end

                  if add_files != [] do
                    Logger.debug(
                      "#{@name}: exists files for adding or updating #{inspect(add_files)}"
                    )

                    remote_files =
                      Enum.reduce(add_files, [], fn file, acc ->
                        case Files.get_by_uuid(file.uuid) do
                          nil ->
                            file
                            |> Map.put(:action_id, action.id)
                            |> Files.add_file_data!()

                            [file | acc]

                          old_file ->
                            Files.update_file_data!(old_file, file)

                            if(old_file.check_sum != file.check_sum,
                              do: [file | acc],
                              else: acc
                            )
                        end
                      end)

                    FilesSyncDownloader.request_download(tag, remote_files, action.uuid)
                  end
                end
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
