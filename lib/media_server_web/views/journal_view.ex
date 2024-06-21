defmodule MediaServerWeb.JournalView do
  use MediaServerWeb, :view

  def render("journal.json", %{ content: items, page: page, page_size: size, total: total}), do:
    %{
      content: normalize_journal(items),
      page: page,
      page_size: size,
      total: total
    }


  defp normalize_journal(items) do
    Enum.map(items, fn(i)->
      %{
        id: i.id,
        filename: i.filename || "",
        ext: i.ext,
        action: i.action,
        token: i.token,
        time: i.inserted_at
      }
    end)
  end
end
