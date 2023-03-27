defmodule PermissionGroups do
  @admin_roles  [:owner, :developer, :employee]
  @employee_roles  [:editor, :contributor, :viewer]
  def get_admin_roles do
    @admin_roles #access attribute
  end
  def get_admin_employee_roles do
    @employee_roles #access attribute
  end
end
defmodule PermissionValues do
  @permissions %{
    "admin" => 1,
    "employee" => 2,
    "user" => 3
  }
  def get_persmission_value(key) do
    @permissions[key]
  end
end
defmodule AdminRolesEnum do
  @roles  [:owner, :developer, :employee]
  def get_roles do
    @roles #access attribute
  end
end
defmodule EmployeeRolesEnum do
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
