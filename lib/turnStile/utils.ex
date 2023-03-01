defmodule TurnStile.Utils do
  @spec sum(number, number) :: number
  def sum(a, b) do
    a + b
  end
  def parens_list(roles_list) do
    Enum.with_index(roles_list)
    |> Enum.map(fn x ->
      value = elem(x, 0)
      index = elem(x, 1)
      cond do
        index == 0 ->
            "('#{value}'"
        index ==  length(roles_list) -1  ->
            "'#{value}')"
        true -> "'#{value}'"
      end
    end)
    |> Enum.join(", ")
  end
end
