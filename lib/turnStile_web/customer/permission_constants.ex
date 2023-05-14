# used my application company
defmodule CompanyPermissionRoles do
  @company_admin_roles  [:system_owner, :system_admin, :system_developer]
  @company_non_admin_roles  [:editor, :contributor, :viewer]
  # add two lists
  @company_roles @company_admin_roles ++ @company_non_admin_roles
  def get_company_admin_roles do
    @company_admin_roles #access attribute
  end
  def get_company_non_admin_roles do
    @company_non_admin_roles #access attribute
  end
  def get_company_all_roles do
    @company_roles #access attribute
  end
end
defmodule CompanyPermissionGroups do
  @permissions %{
    "system_owner" => 1,
    "system_developer" => 2,
    "system_admin" => 3,
    "editor" => 4,
    "contributor" => 5,
    "viewer" => 6
  }
  def get_persmission_value(key) do
    @permissions[key]
  end
end
defmodule CompanyAdminRolesEnum do
  @roles  [:system_owner, :system_developer, :system_admin]
  def get_roles do
    @roles #access attribute
  end
end
defmodule CompanyNonAdminRolesEnum do
  @roles  [:editor, :contributor, :viewer]
  def get_roles do
    @roles #access attribute
  end
end

# used by end users
defmodule EmployeePermissionRoles do
  @employee_admin_roles  [:owner, :developer, :admin]
  @employee_non_admin_roles  [:editor, :contributor, :viewer]
  # add two lists
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
