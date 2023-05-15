defmodule TurnStileWeb.Plugs.RouteType do
  import Plug.Conn

  @route_types ["admin", "non-admins"]

  def init(default), do: default

  def call(conn, default) do
    # set route as admin or non-admin
   if length(conn.path_info) > 0 && (hd conn.path_info) in @route_types do
       assign(conn, :route_type, (hd conn.path_info))
    else
      assign(conn, :route_type, default)
   end
  end
end
