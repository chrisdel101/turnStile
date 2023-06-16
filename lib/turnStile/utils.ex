defmodule TurnStile.Utils do
  # drop all values in list before index
  # IN: list - list to check
  # IN: to_match - item to match
  # OUT: list w single item
  def display_single_item_list(list_to_check, to_match) do
    # return index of item
    item = Enum.find(list_to_check, fn x -> x == to_match end)

    if item do
      [item]
    else
      raise ArgumentError, message: "Error in display_only. Index not found"
    end
  end

  # drop all values in list before index
  # IN: list of atoms - to check
  # IN: role - string
  # OUT: index of item
  def display_forward_list_values(list_to_check, role_str) do
    # return index of :atom item in list
    index = Enum.find_index(list_to_check, &(&1 == String.to_atom(role_str)))

    if index do
      Enum.drop(list_to_check, index)
    else
      raise ArgumentError, message: "Error in display_forward_list_values. Index not found"
    end
  end


# convert a list to a string with parenthese "()" - used for DB enum type syntax - https://stackoverflow.com/a/37216214/5972531
  def convert_to_parens_string(roles_list) do
    x = Enum.with_index(roles_list)
    |> Enum.map(fn x ->
      value = elem(x, 0)
      index = elem(x, 1)

      cond do
        index == 0 ->
          "('#{value}'"

        index == length(roles_list) - 1 ->
          "'#{value}')"

        true ->
          "'#{value}'"
      end
    end)
    |> Enum.join(", ")
    IO.puts("#{x}")
    x
  end

  def is_digit(str) do
    case Integer.parse(str) do
      {_, ""} -> true
      _ -> false
    end
  end

  # TODO - add env guards
  def convert_to_int(value) do
    if !is_nil(value) do
      case value do
        integer when is_integer(integer) ->
          integer

        float when is_float(float) ->
          round(float)

        string when is_binary(string) ->
          case String.to_integer(string) do
            integer when is_integer(integer) -> integer
            _ -> 0
          end

        _ ->
          0
        end
      else
        nil
    end
  end

  def read_json(json_file) do
    json_file
    |> File.read!()
    |> Jason.decode!()
  end

end
