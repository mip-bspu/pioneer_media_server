defmodule MediaServerWeb.ErrorView do
  use MediaServerWeb, :view

  def render("unauthorized.json", message), do:
    %{ errors: %{statusText: "Unauthorized", message: get_message(message)} }

  defp get_message(error) do
    case error do
      %{message: message}->message
      message -> message
    end
  end
end
