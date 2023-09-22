defmodule TurnStileWeb.PageController do
  use TurnStileWeb, :controller
  alias TurnStile.Staff
  alias TurnStile.Utils
  # import Phoenix.LiveView
  # import Phoenix.LiveView.Utils


  def index(conn, _params) do
    conn
      |> render("index.html")
  end
  # called via /clear_sessions route
  def clear_sessions(conn, _params) do
    conn=Plug.Conn.clear_session(conn)
    IO.inspect("Clear Session Routes")
    IO.inspect(Plug.Conn.get_session(conn))
    conn
    |> put_flash(:info, "Session cleared")
    |> redirect(to: Routes.page_path(conn, :index))
  end

end
