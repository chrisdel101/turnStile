

defmodule PermissionGroups do
  @admin_roles  [:owner, :developer, :admin]
  @employee_roles  [:editor, :contributor, :viewer]
  def get_admimn_roles do
    @admin_roles #access attribute
  end
  def get_admin_employeer_roles do
    @employee_roles #access attribute
  end
end
defmodule PermissionValues do
  @permissions %{
    "admin" => 1,
    "employee" => 2,
    "user" => 3
  }
end
defmodule AdminRolesEnum do
  @roles  [:owner, :developer, :admin]
  def get_roles do
    @roles #access attribute
  end
end
defmodule EmployeeRolesEnum do
  @roles  [:owner, :developer, :admin, :editor, :contributor, :viewer]
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
