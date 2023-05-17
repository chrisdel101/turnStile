defmodule TurnStileWeb.Plugs.ClientType do
  import Plug.Conn

  def init(default), do: default

  def call(conn, default) do
    set_client_type(conn, default)
  end

  # set client type
  defp set_client_type(conn, _client_type) do
  #  IO.inspect(conn.assigns)
  #  IO.inspect("HERE ")
    # if length(conn.path_info) > 0 && hd(conn.path_info) in RoutePermissions.get_route_types() do
    #   assign(conn, :route_type, hd(conn.path_info))
    # else
    #   assign(conn, :route_type, default)
    # end
    conn
  end
end
