defmodule MediaServer.Content.FileTag do
  use Ecto.Schema

  alias MediaServer.Content

  schema "file_tags" do
    belongs_to :file, Content.File
    belongs_to :tag, Content.Tag
  end
end
