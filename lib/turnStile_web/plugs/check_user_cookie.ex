defmodule TurnStileWeb.Plugs.CheckUserCookie do
  import Plug.Conn
  use TurnStileWeb, :controller


  alias TurnStile.Patients.User

  def init(default), do: default

  def call(conn, _params) do
    check_if_user_cookies(conn)
  end

  # check if user cookie exists on each request
  def check_if_user_cookies(conn) do
    cookies_conn = fetch_cookies(conn)
    cookies = Map.get(cookies_conn, :cookies)
    case TurnStile.Utils.check_if_user_cookie(cookies) do
      {%User{} = user, encoded_token} ->
        conn
        |> redirect(to: Routes.user_confirmation_path(conn, :new, user.id, encoded_token))
        # |> halt()
      nil ->
        conn
    end
    conn
  end
end
