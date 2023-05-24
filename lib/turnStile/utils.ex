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
# checks persmission level of input role
# IN: role: string
# OUT: int - 1-3 from EmployeePermissionGroups
  def get_employee_permissions_level(role) do
      # role = current_user.role
      cond do
        # check if employee persmission
        Enum.member?(EmployeePermissionRoles.get_employee_manager_roles, role) -> 1
        # check if employee persmission
        Enum.member?(EmployeePermissionRoles.get_employee_non_manager_roles, role) -> 2
        "default" -> 3
    end
  end
  def get_admin_permissions_level(role) do
      # role = current_user.role
      cond do
        # check if employee persmission
        Enum.member?(AdminPermissionRoles.get_admin_manager_roles, role) -> 1
        # check if employee persmission
        Enum.member?(AdminPermissionRoles.get_admin_non_manager_roles, role) -> 2
        "default" -> 3
    end
  end
  # convert a list to a string with parenthese "()" - used for DB enum type syntax - https://stackoverflow.com/a/37216214/5972531
  def convert_to_parens_string(roles_list) do
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
  def is_digit(str) do
    case Integer.parse(str) do
      {_, ""} -> true
      _ -> false
    end
  end
  # TODO - add env guards
  def convert_to_int(value) do
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
      _ -> 0
    end
  end


  def read_json(json_file) do
    json_file
    |> File.read!()
    |> Jason.decode!()
  end
end
