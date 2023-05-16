defmodule TurnStileWeb.Plugs.RouteType do
  import Plug.Conn

  def init(default), do: default

  def call(conn, default) do
    set_route_type(conn, default)
  end

  # admin or non-admin route
  defp set_route_type(conn, default) do
    # check if 1st path is /admin
    if length(conn.path_info) > 0 && hd(conn.path_info) in RouteTypesEnum.get_route_types() do
      assign(conn, :route_type, hd(conn.path_info))
    else
      assign(conn, :route_type, default)
    end
  end
end
