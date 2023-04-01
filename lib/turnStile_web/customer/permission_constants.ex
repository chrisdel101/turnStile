defmodule EmployeePermissionRoles do
  @employee_admin_roles  [:owner, :developer, :admin]
  @employee_non_admin_roles  [:editor, :contributor, :viewer]
  @employee_roles @employee_admin_roles ++ @employee_non_admin_roles
  def get_employee_admin_roles do
    @employee_admin_roles #access attribute
  end
  def get_employee_non_admin_roles do
    @employee_non_admin_roles #access attribute
  end
  def get_employee_all_roles do
    @employee_roles #access attribute
  end
end
defmodule PermissionGroups do
  @permissions %{
    "owner" => 1,
    "developer" => 2,
    "admin" => 3,
    "editor" => 4,
    "contributor" => 5,
    "viewer" => 6
  }
  def get_persmission_value(key) do
    @permissions[key]
  end
end
defmodule EmployeeAdminRolesEnum do
  @roles  [:owner, :developer, :admin]
  def get_roles do
    @roles #access attribute
  end
end
defmodule EmployeeNonAdminRolesEnum do
  @roles  [:editor, :contributor, :viewer]
  def get_roles do
    @roles #access attribute
  end
end
defmodule AlertTypesEnum do
  @roles  [:initial, :confirmation, :req_for_conf, :cancellation, :change]
  def get_roles do
    @roles #access attribute
  end
end
