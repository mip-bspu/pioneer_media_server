defmodule MediaServer.Content.FileTag do
  use Ecto.Schema

  alias MediaServer.Content
  alias MediaServer.Tags

  schema "file_tags" do
    belongs_to :file, Content.File
    belongs_to :tag, Tags.Tag
  end
end
