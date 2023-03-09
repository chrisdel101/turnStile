defmodule TurnStile.Utils do

# check with persmission level current user has
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
