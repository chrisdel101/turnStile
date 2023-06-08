# TODO - remove enum  where not enum
# - leaving for now since easier to search for RouteTypesEnum than just RouteTypes
defmodule RouteTypesEnum do
  @moduledoc """
  Route Types.
  Ggetters for route types
   - Types are used to determine what type of route is being accessing by a client.
  ex /admin or not-/admin
  """
  @route_types %{
    "ADMIN" => "admin",
    "NON-ADMIN" => "non-admin"
  }
  def get_route_types do
    @route_types
  end
  def get_route_type_value(key) do
    Map.get(@route_types, key)
  end
end

defmodule RoleValuesMap do
  @moduledoc """
    Role values for permissio
    - Used to determine access level by value
  """
  @permission_role_values %{
    "owner" => 1,
    "developer" => 2,
    "admin" => 3,
    "editor" => 4,
    "contributor" => 5,
    "viewer" => 6
  }
  @permission_roles %{
    "owner" => "owner",
    "developer" => "developer",
    "admin" =>  "admin",
    "editor" => "editor",
    "contributor" =>  "contributor",
    "viewer" =>  "viewer"
  }
  def get_permission_role_values do
    @permission_role_values
  end

  def get_permission_roles do
    @permission_roles
  end

  def get_permission_role(key) do
    Map.get(@permission_roles, key)
  end
  def get_permission_role_value(key) do
    Map.get(@permission_role_values, key)
  end
end

defmodule ClientTypesEnum do
  @moduledoc """
    Client types
    getters for client types
    - Types are used to determine what type of client is accessing the system.
    example: true admin, employee, user, guest
  """
  @client_types ["admin", "employee", "user", "guest"]
  def get_client_types do
    @client_types
  end

  def get_client_type_value(type) do
    Enum.find(@client_types, &(&1 == type))
  end
end
