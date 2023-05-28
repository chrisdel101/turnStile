defmodule RouteTypesEnum do
  @moduledoc """
  Route Types.
  Ggetters for route types
   - Types are used to determine what type of route is being accessing by a client.
  ex /admin or not-/admin
  """
  @route_types ["admin", "non-admins"]
  def get_route_types do
    @route_types #getter
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
