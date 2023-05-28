defmodule TurnStileWeb.Plugs.EmptyParams do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _params) do
    empty_session_by_key(conn)
  end

  # fire when query str empty=true
  def empty_session_by_key(conn) do
  #  check for query param flags,; check exists in sessions
    if Map.has_key?(conn.query_params, "emptyParams") &&
     conn.query_params["emptyParams"] == "true" &&
     Map.has_key?(conn.query_params, "paramsKey") &&
     is_map(Plug.Conn.get_session(conn)[conn.query_params["paramsKey"]]) do
        IO.inspect("Empty seesion params plug")
        session_key_name = conn.query_params["paramsKey"]
        conn |>
        Plug.Conn.delete_session(session_key_name)
    else
      conn
    end
  end
end
