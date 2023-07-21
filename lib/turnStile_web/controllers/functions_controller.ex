defmodule TurnStileWeb.FunctionsController do
  use TurnStileWeb, :controller
  import Plug.Conn
    # called via /clear_sessions route
  def clear_sessions(conn, _params) do
    if Mix.env() !== :dev do
      IO.puts("Cannot clear sessions in production.")
      conn
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
      conn
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
      conn
      |> redirect(to: Routes.page_path(conn, :index))
      conn
    else
      conn =
        conn
      |> put_resp_cookie("third", %{user_id: 999}, sign: true)
      # IO.inspect(conn)

      # IO.inspect(conn)
      # conn  = fetch_cookies(conn, signed: ~w(my-cookie1))
      IO.inspect(conn.cookies)
      conn
      |> put_resp_cookie("third", %{user_id: 999}, sign: true)
      |> resp(200, "set_cookie: see console")
      |> send_resp()
    end
  end

  @spec get_cookies(Plug.Conn.t(), any) :: Plug.Conn.t()
  def get_cookies(conn, _params) do
    if Mix.env() !== :dev do
      IO.puts("Cannot get cookies in production.")
      conn
      |> redirect(to: Routes.page_path(conn, :index))
      conn
    else
      cookies1 = fetch_cookies(conn)
    cookies2 = Map.get(conn, :cookies)
    IO.inspect(cookies1, label: "COOKIES1")
    IO.inspect(cookies2, label: "COOKIES2")

      # IO.inspect(conn.cookies)
      # IO.inspect(conn.cookies)
      # |> put_resp_cookie("my-cookie", %{user_id: 999}, sign: true)
      conn
      |> resp(200, "get_cookies: see console")
      |> send_resp()
    end
  end
end
