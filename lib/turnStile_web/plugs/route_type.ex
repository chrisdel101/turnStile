defmodule TurnStileWeb.Plugs.RouteType do
  import Plug.Conn

  def init(default), do: default

  def call(conn, default) do
    set_route_type(conn, default)
  end

  # admin or non-admin route
  defp set_route_type(conn, default) do
    if length(conn.path_info) > 0 do
      path_info_head = hd(conn.path_info)
      admin = RouteTypesEnum.get_route_type_value("ADMIN")
      test = RouteTypesEnum.get_route_type_value("TEST")

      route_type =
        case path_info_head do
          ^admin ->
            path_info_head

          ^test ->
            path_info_head

          _ ->
            default
        end
      assign(conn, :route_type, route_type)
    end
  end
end
