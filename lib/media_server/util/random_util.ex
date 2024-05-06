defmodule MediaServer.Util.RandomUtil do
  def get_num_of_rand_elems(elems, num) when length(elems) == 0 or num == 0, do: []
  def get_num_of_rand_elems(elems, num) do
    rand_elem = Enum.map(elems, fn(e)->e.priority end) |> random_choice(elems)
    [rand_elem | get_num_of_rand_elems(elems--[rand_elem], num-1)]
  end

  def random_choice(ws, its) when length(ws) == 0 or length(its) == 0 or length(ws) != length(its), do: nil
  def random_choice(priorities, items), do:
    get_random_number(priorities)
    |> get_item_by_rand_num(0, priorities, items)

  defp get_item_by_rand_num(rn, sum, [w], [it]), do: it
  defp get_item_by_rand_num(rn, sum, [w | ws], [it | its]) when rn <= sum+w, do: it
  defp get_item_by_rand_num(rn, sum, [w | ws], [it | its]), do: get_item_by_rand_num(rn, sum+w, ws, its)

  defp get_random_number(priorities) do
    max = priorities |> Enum.sum()
    0..max |> Enum.random()
  end
end
# MediaServer.Util.RandomUtil.get_num_of_rand_elems([%{priority: 3, id: 1}, %{priority: 2, id: 2}, %{priority: 1, id: 3}], 2)
