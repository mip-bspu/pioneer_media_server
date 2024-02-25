defmodule MediaServer.NodeServer do

  alias MediaServer.Repo
  alias MediaServer.NodeServer.Node

  def add_nodes(nodes) do
    Enum.each(nodes, fn(%{name: name})->
      %Node{name: name}
      |> Node.changeset()
      |> Repo.insert()
    end)
  end
end
