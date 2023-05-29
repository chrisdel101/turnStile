defmodule RouteTypesEnum do
  @moduledoc """
  Route Types.
  Ggetters for route types
   - Types are used to determine what type of route is being accessing by a client.
  ex /admin or not-/admin
  """
  @route_types ["admin", "non-admins"]
  def get_route_types do
    # getter
    @route_types
  end
end

defmodule RoleValuesEnum do
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
  def get_permission_role_values do
    @permission_role_values
  end

  def get_permission_value(key) do
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
