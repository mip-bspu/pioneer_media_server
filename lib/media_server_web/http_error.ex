defmodule InternalServerError do
  defexception [message: "Ошибка сервера", plag_status: 500]
end
