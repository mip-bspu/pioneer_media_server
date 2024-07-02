defmodule MediaServer.Server do
  @image_formats Application.compile_env(:media_server, :image_formats)
  @video_formats Application.compile_env(:media_server, :video_formats)

  def get_formats_available(), do: %{
      image_formats: @image_formats,
      video_formats: @video_formats
    }
end
