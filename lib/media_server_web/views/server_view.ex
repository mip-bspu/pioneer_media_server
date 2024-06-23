defmodule MediaServerWeb.ServerView do
  use MediaServerWeb, :view

  def render("setup.json", %{setup: setup}), do:
    %{
      content: %{
        image_formats: setup.content.image_formats,
        video_formats: setup.content.video_formats
      }
    }
end
