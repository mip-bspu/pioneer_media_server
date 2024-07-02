defmodule MediaServer.Util.FormatUtil do

  def to_integer(int, default \\ 0) do
    if is_integer(int) do
      int
    else
      case Integer.parse(int, 10) do
        :error -> default
        {int, _} -> int
      end
    end
  end

  def to_atom(key) when is_bitstring(key), do: String.to_atom(key)
  def to_atom(key), do: key

  def to_maps_key_atom(list_map), do: Enum.map(list_map, &to_map_key_atom(&1))
  def to_map_key_atom(map), do: Map.new(map, fn {k, v} -> {to_atom(k), v} end)
end
