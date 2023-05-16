defmodule RouteTypesEnum do
  @doc """
   Route types.
   getters for route types
   - Types are used to determine what type of route is being accessing by a client.
 """
  @route_types ["admin", "non-admins"]
  def get_route_types do
    @route_types #getter
  end
end
defmodule ClientTypesEnum do
  @doc """
   Client types
   getters for client types
   - Types are used to determine what type of client is accessing the system.
 """
  @client_types ["admin", "employee", "user", "guest"]
  def get_client_types do
    @client_types
  end
  def get_client_type_value(type) do
    Enum.find(@client_types, &(&1 == type))
  end
end
