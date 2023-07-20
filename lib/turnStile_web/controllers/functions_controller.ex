defmodule TurnStileWeb.FunctionsController do
  use TurnStileWeb, :controller
  import Plug.Conn
  import Jason
  # called via /clear_sessions route
  def clear_sessions(conn, _params) do
    if Mix.env() !== :dev do
      IO.puts("Cannot clear sessions in production.")
      |> redirect(to: Routes.page_path(conn, :index))

      conn
    else
      conn = Plug.Conn.clear_session(conn)
      IO.inspect("Clear Session Routes")
      IO.inspect(Plug.Conn.get_session(conn))

      conn
      |> put_flash(:info, "Session cleared")
      |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def get_sessions(conn, _params) do
    if Mix.env() !== :dev do
      IO.puts("Cannot clear sessions in production.")
      |> redirect(to: Routes.page_path(conn, :index))
      conn
    else
      IO.inspect(Plug.Conn.get_session(conn), label: "see_session_values")
      conn
      |> resp(200, "Get session: see console")
      |> send_resp()
    end
  end

  def set_cookie(conn, _params) do
    if Mix.env() !== :dev do
      IO.puts("Cannot set cookies in production.")
      |> redirect(to: Routes.page_path(conn, :index))
      conn
    else
      conn =
        conn
      |> put_resp_cookie("my-cookie", %{user_id: 999}, sign: true, max_age: 30)
      # IO.inspect(conn)

      # IO.inspect(conn)
      # conn  = fetch_cookies(conn, signed: ~w(my-cookie1))
      IO.inspect(conn.cookies)

      conn
    end
  end

  def get_cookies(conn, _params) do
    if Mix.env() !== :dev do
      IO.puts("Cannot get cookies in production.")
      |> redirect(to: Routes.page_path(conn, :index))
      conn
    else
      cookie = conn
      |> fetch_cookies(signed: ~w(my-cookie))
      IO.inspect(cookie.cookies)
      # IO.inspect(conn.cookies)
      # |> put_resp_cookie("my-cookie", %{user_id: 999}, sign: true)
      conn
    end
  end
end
