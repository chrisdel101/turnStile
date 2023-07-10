defmodule ListSearch do
  def list_search(list, search_term) do
    Enum.filter(list, fn(map) -> if !!Map.get(map, search_term), do: map, else: nil end)
  end
end
