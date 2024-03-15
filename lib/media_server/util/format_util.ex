defmodule MediaServer.Util.FormatUtil do
  def to_integer(int) when is_integer(int), do: int
  def to_integer(int) do
    case Integer.parse(int, 10) do
      :error->0
      {int, _}->int
    end
  end
end
