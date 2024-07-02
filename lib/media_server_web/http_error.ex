defmodule BadRequestError do
  defexception message: "Плохой запрос", plug_status: 400
end

defmodule UnauthorizedError do
  defexception message: "Пользователь не авторизован", plug_status: 401
end

defmodule NotFound do
  defexception message: "Ресурс не найден", plug_status: 404
end

defmodule InternalServerError do
  defexception message: "Ошибка сервера", plug_status: 500
end
