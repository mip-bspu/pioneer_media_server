defmodule MediaServerWeb.AMQP.FilesSyncDownloader do
  use GenServer
  require Logger

  alias MediaServerWeb.Rpc.RpcClient
  alias MediaServer.Files

  @name __MODULE__
  @my_tag Application.compile_env(:media_server, :queue_tag)

  def start_link(state), do: GenServer.start_link(@name, state, name: @name)

  def init(_state) do
    Logger.info("#{@name}: starting files sync downloader")
    {:ok, %{action_uuids: []}}
  end

  def request_download(tag, files, action_uuid),
    do: GenServer.cast(@name, {:request_download, tag, files, action_uuid})

  def load_chunk(chunk, action_uuid), do: GenServer.cast(@name, {:load_chunk, chunk, action_uuid})

  def get_state_download(action_uuid),
    do: GenServer.call(@name, {:get_state_download, action_uuid})

  def delete_state_download(action_uuid),
    do: GenServer.cast(@name, {:delete_state_download, action_uuid})

  def handle_call({:get_state_download, action_uuid}, _from, %{action_uuids: uuids} = state),
    do: {:reply, if(action_uuid in uuids, do: :load, else: :none), state}

  def handle_cast({:delete_state_download, action_uuid}, %{action_uuids: uuids} = state),
    do: {:noreply, %{state | action_uuids: uuids -- [action_uuid]}}

  def handle_cast({:request_download, tag, files, action_uuid}, %{action_uuids: uuids} = state) do
    Logger.debug("#{@name}: request download #{inspect(files)} from #{tag}")

    new_state =
      if action_uuid not in uuids do
        Enum.each(files, fn file ->
          spawn(fn ->
            case RpcClient.request_file_download(tag, @my_tag, file.uuid, action_uuid) do
              {:ok, _ok} ->
                Logger.debug("#{@name}: the download starts: #{file.name}")

              {:error, reason} ->
                Logger.warning(
                  "#{@name}: error request download from #{tag} file #{file.name}: #{inspect(reason)}, deleting..."
                )

                Files.delete_file!(file)
                delete_state_download(action_uuid)
            end
          end)
        end)

        %{state | action_uuids: [action_uuid | uuids]}
      else
        state
      end

    {:noreply, new_state}
  end

  def handle_cast({:load_chunk, chunk, action_uuid}, %{action_uuids: uuids} = state) do
    new_state =
      if action_uuid in uuids do
        case chunk do
          %{state: "load"} ->
            Files.load_file(chunk)
            state

          %{state: "last"} ->
            spawn(fn ->
              file = Files.get_by_uuid(chunk.uuid)

              check_sum =
                chunk
                |> Files.file_path()
                |> Files.create_hash_sum()

              if file.check_sum == check_sum do
                Logger.debug("#{@name}: download successfully for file #{file.name}")
              else
                Logger.debug("#{@name}: download error for file #{file.name}, deleting...")
                Files.delete_file!(file)
              end
            end)

            %{state | action_uuids: uuids -- [action_uuid]}

          %{state: "cancel"} ->
            Logger.debug("#{@name}: download error on parent server, deleting...")
            Files.delete_file!(%{uuid: chunk.uuid, extention: chunk.extention})

            %{state | action_uuids: uuids -- [action_uuid]}
        end
      else
        state
      end

    {:noreply, new_state}
  end
end
