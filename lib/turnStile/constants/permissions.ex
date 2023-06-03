defmodule AdminPermissionRoles do
  @doc """
   ADMIN permission constants.
   getters, rankings, enums for admin permissions
 """
  @admin_manager_roles [:owner, :developer, :admin]
  @admin_non_manager_roles  [:editor, :contributor, :viewer]
  # add two lists
  @admin_roles @admin_manager_roles ++ @admin_non_manager_roles
  def get_admin_manager_roles do
    @admin_manager_roles #getter
  end
  def get_admin_non_manager_roles do
    @admin_non_manager_roles #getter
  end
  def get_admin_all_roles do
    @admin_roles #getter
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
    @roles #getter
  end
end
defmodule AdminNonManagerRolesEnum do
  @roles  [:editor, :contributor, :viewer]
  def get_roles do
    @roles #getter
  end
end
# EmployeePermissionRoles being used to populate DB for both employee and admins
# TODO - maybe seperate tables if required
defmodule EmployeePermissionRoles do
  @doc """
   END-USER permission constants.
   getters, rankings, enums for all end-users (non-admin) permissions
 """
  @employee_manager_roles  [:owner, :developer, :admin]
  @employee_non_manager_roles  [:editor, :contributor, :viewer]
  # add two lists
  @employee_roles @employee_manager_roles ++ @employee_non_manager_roles
  def get_employee_manager_roles do
    @employee_manager_roles #getter
  end
  def get_employee_non_manager_roles do
    @employee_non_manager_roles #getter
  end
  def get_employee_all_roles do
    @employee_roles #getter
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
  # all values GE (including) have write permissions
  @edit_permissions_threshold 3
  def get_persmission_value(key) do
    @permissions[key]
  end
  def permissions, do: @permissions
  def edit_permissions_threshold, do: @edit_permissions_threshold
end
defmodule EmployeeManagerRolesEnum do
  @roles  [:owner, :developer, :admin]
  def get_roles do
    @roles #getter
  end
end
defmodule EmployeeNonManagerRolesEnum do
  @roles  [:editor, :contributor, :viewer]
  def get_roles do
    @roles #getter
  end
end
defmodule AlertTypesEnum do
  @roles  [:initial, :confirmation, :req_for_conf, :cancellation, :change]
  def get_roles do
    @roles #getter
  end
end
