defmodule TurnStile.Utils do

# drop all values in list before index
# IN: list of atoms - to check
# IN: role - string
# OUT: index of item
  def display_forward_list_values(list_to_check, role_str) do
    # return index of item
    index = Enum.find_index(list_to_check, &(&1 == String.to_atom(role_str)))
      if index do
        Enum.drop(list_to_check, index)
      else
        raise ArgumentError, message: "Error in display_forward_list_values. Index not found"
    end

  end
# checks persmission level of input role
# IN: role: string
# OUT: int 1-3 from PermissionValues
  def define_permissions_level(role) do
      # role = current_user.role
      IO.puts("define_permissions_level Role: ")
      IO.inspect(role)
      cond do
        # check if admin persmission
        Enum.member?(PermissionGroups.get_admimn_roles, role) -> 1
        # check if employee persmission
        Enum.member?(PermissionGroups.get_admin_employeer_roles, role) -> 2
        "default" -> 3
    end
  end
  # convert a list to a string with parenthese "()"
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
end
