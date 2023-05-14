# ADMINS
defmodule AdminPermissionRoles do
  @admin_manager_roles [:owner, :developer, :admin]
  @admin_non_manager_roles  [:editor, :contributor, :viewer]
  # add two lists
  @admin_roles @admin_manager_roles ++ @admin_non_manager_roles
  def get_admin_manager_roles do
    @admin_manager_roles #access attribute
  end
  def get_admin_non_manager_roles do
    @admin_non_manager_roles #access attribute
  end
  def get_admin_all_roles do
    @admin_roles #access attribute
  end
end
defmodule AdminPermissionGroups do
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
defmodule AdminManagerRolesEnum do
  @roles  [:owner, :developer, :admin]
  def get_roles do
    @roles #access attribute
  end
end
defmodule AdminNonManagerRolesEnum do
  @roles  [:editor, :contributor, :viewer]
  def get_roles do
    @roles #access attribute
  end
end

# END USERS
defmodule EmployeePermissionRoles do
  @employee_manager_roles  [:owner, :developer, :admin]
  @employee_non_manager_roles  [:editor, :contributor, :viewer]
  # add two lists
  @employee_roles @employee_manager_roles ++ @employee_non_manager_roles
  def get_employee_manager_roles do
    @employee_manager_roles #access attribute
  end
  def get_employee_non_manager_roles do
    @employee_non_manager_roles #access attribute
  end
  def get_employee_all_roles do
    @employee_roles #access attribute
  end
end
defmodule EmployeePermissionGroups do
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
defmodule EmployeeManagerRolesEnum do
  @roles  [:owner, :developer, :admin]
  def get_roles do
    @roles #access attribute
  end
end
defmodule EmployeeNonManagerRolesEnum do
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
