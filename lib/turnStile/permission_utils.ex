defmodule TurnStile.PermissionsUtils do
  @doc """
   # checks persmission level of input role
  # IN: role: string
  # OUT: int - 1-3 from
  """
  @permissions_levels [1, 2, 3]
  def get_permission_levels do
    @permissions_levels
  end
  def get_employee_permissions_level(role) do
    # role is current_user.role
    cond do
      # check if employee persmission
      Enum.member?(EmployeePermissionRoles.get_employee_manager_roles(), role) -> 1
      # check if employee persmission
      Enum.member?(EmployeePermissionRoles.get_employee_non_manager_roles(), role) -> 2
      "default" -> 3
    end
  end

  def get_admin_permissions_level(role) do
    # role is current_user.role
    cond do
      # check if employee persmission
      Enum.member?(AdminPermissionRoles.get_admin_manager_roles(), role) -> 1
      # check if employee persmission
      Enum.member?(AdminPermissionRoles.get_admin_non_manager_roles(), role) -> 2
      "default" -> 3
    end
  end

  @doc """
  # checks if client has write access
  - determines if route can be visited
  # @permissions %{
  #   "owner" => 1,
  #   "developer" => 2,
  #   "admin" => 3,
  #   "editor" => 4,
  #   "contributor" => 5,
  #   "viewer" => 6
  # }
  """
  def client_has_write_access?(conn, _params) do
    current_user = conn.assigns[:current_user]
    # safely extract role value
    role_value = Kernel.get_in(current_user, [:role_value])
    IO.inspect("TTTTTTTT")
    IO.inspect(role_value)
    if role_value <= 3 do
      true
    else
      false
    end
  end
end
