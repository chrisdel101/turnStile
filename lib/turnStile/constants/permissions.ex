defmodule AdminPermissionRolesEnum do
  @moduledoc """
    ADMIN permission listings.
    getters, rankings, enums for admin permissions
  """
  @admin_manager_roles [:owner, :developer, :admin]
  @admin_non_manager_roles [:editor, :contributor, :viewer]
  # add two lists
  @admin_roles @admin_manager_roles ++ @admin_non_manager_roles
  def get_admin_manager_roles do
    # getter
    @admin_manager_roles
  end

  def get_admin_non_manager_roles do
    # getter
    @admin_non_manager_roles
  end

  def get_admin_all_roles do
    # getter
    @admin_roles
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
  @roles [:owner, :developer, :admin]
  def get_roles do
    # getter
    @roles
  end
end

defmodule AdminNonManagerRolesEnum do
  @roles [:editor, :contributor, :viewer]
  def get_roles do
    # getter
    @roles
  end
end
defmodule EmployeePermissionRolesEnum do

  @moduledoc """
   EmployeePermissionRolesEnum
   - Used when role iteration is required
   - Useful to dropping list items, or starting at certain index
   - For role getters use commmon.ex
  """
  @employee_manager_roles [:owner, :developer, :admin]
  @employee_non_manager_roles [:editor, :contributor, :viewer]
  # add two lists
  @employee_roles @employee_manager_roles ++ @employee_non_manager_roles
  def get_employee_manager_roles do
    # getter
    @employee_manager_roles
  end

  def get_employee_non_manager_roles do
    # getter
    @employee_non_manager_roles
  end

  def get_employee_all_roles do
    # getter
    @employee_roles
  end
end

defmodule EmployeePermissionThresholds do
  @moduledoc """
   EmployeePermissionThresholds
   - Used to check if employee passes theresholds
  """
  @permissions %{
    "owner" => 1,
    "developer" => 2,
    "admin" => 3,
    "editor" => 4,
    "contributor" => 5,
    "viewer" => 6
  }
  # all values <= (GT_E) have write permissions
  @edit_organization_permissions_threshold 3
  @is_admin_employee_threshold 3
  @edit_employee_permissions_threshold 3
  @register_employee_permissions_threshold 3
  @add_user_permissions_threshold 5
  @edit_user_permissions_threshold 4
  @delete_user_permissions_threshold 4
  @remove_user_permissions_threshold 5 # removes/sets to inactive but not deletes
  @send_alert_permissions_threshold 5
  def get_persmission_value(key) do
    @permissions[key]
  end

  def permissions, do: @permissions
  def is_admin_employee_threshold, do: @is_admin_employee_threshold
  def edit_employee_permissions_threshold, do: @edit_employee_permissions_threshold
  def delete_user_permissions_threshold, do: @delete_user_permissions_threshold
  def register_employee_permissions_threshold, do: @register_employee_permissions_threshold
  def add_user_permissions_threshold, do: @add_user_permissions_threshold
  def edit_user_permissions_threshold, do: @edit_user_permissions_threshold
  def send_alert_permissions_threshold, do: @send_alert_permissions_threshold
  def remove_user_permissions_threshold, do: @remove_user_permissions_threshold
  def edit_organization_permissions_threshold, do: @edit_organization_permissions_threshold
end

defmodule EmployeeManagerRolesEnum do
  @roles [:owner, :developer, :admin]
  @spec get_roles :: [:admin | :developer | :owner, ...]
  def get_roles do
    # getter
    @roles
  end
end

defmodule EmployeeNonManagerRolesEnum do
  @roles [:editor, :contributor, :viewer]
  def get_roles do
    # getter
    @roles
  end
end
