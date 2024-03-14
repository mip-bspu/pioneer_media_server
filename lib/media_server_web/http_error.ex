defmodule BadRequestError do
  defexception message: "Плохой запрос", plug_status: 400
end

defmodule InternalServerError do
  defexception message: "Ошибка сервера", plag_status: 500
end
