defmodule MediaServerWeb.ErrorJSON do
  require Logger

  # If you want to customize a particular status code,
  # you may add your own clauses, such as:
  #
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def render(template, assigns) do
    if assigns.status == 500 do
      assigns.conn.assigns
      |> Logger.error
    end

    %{errors: %{
      detail: Phoenix.Controller.status_message_from_template(template),
      message: get_message(assigns.reason)
    }}
  end

  defp get_message(error) do
    case error do
      %{message: message} -> message
      message -> message
    end
  end
end
