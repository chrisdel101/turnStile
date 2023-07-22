defmodule TurnStileWeb.UserConfirmationController do
  use TurnStileWeb, :controller
  import Plug.Conn

  alias TurnStile.Patients
  alias TurnStile.Patients.User
  @json TurnStile.Utils.read_json("sms.json")

  @cookie_opts []

  def new(conn, %{"user_id" => _user_id, "token" => token}) do
    case handle_cookie_parse(conn) do
      {%User{} = user, encoded_token} ->
        IO.inspect(user, label: "USER HERE")
        conn
        |> render("new.html", token: token, json: @json, user: user)
        |> halt()
      nil ->
          # check URL token - match url to hashed-token in DB
          case Patients.confirm_user_email_token(token) do
            {:ok, user} ->
              IO.inspect(user, label: "USER")
              # # add new cookie token -
              {bytes_token, user_token} = Patients.generate_and_insert_user_session_token(user)
              IO.inspect(bytes_token, label: "bytes_token")
              IO.inspect(user_token, label: "user_token")
              IO.inspect(Base.encode64(bytes_token), label: "encoded 64 bytes_token")
              conn
              |>  encode_and_write_cookie(bytes_token, user.id)
              |>  render("new.html", token: token, json: @json, user: user)
            :not_found ->
              # no users matching
              IO.puts("user not_found")
            end

    end
    # first validate user by URL token
  end
  def handle_cookie_parse(conn) do
    cookies_conn = fetch_cookies(conn)
    cookies = Map.get(cookies_conn, :cookies)
    IO.inspect(cookies, label: "COOKIES1")
    TurnStile.Utils.check_if_user_cookie(cookies)
    # IO.inspect(result, label: "USER")


    # # # check for user_id cookie
    # user_cookie = Map.get(cookies, "user-#{user_id}")
    # if user_cookie do
    #   IO.inspect(token)
    #   IO.inspect(Base.encode64(token), label: "COOKIES found")

    #   user = Patients.get_user_by_session_token(token)
    #   IO.inspect(user)
    #   # decode user_cookie
  end

  def update(conn, %{"_action" => "confirm"}) do
    # Handle confirm action
  end

  def update(conn, %{"_action" => "cancel"}) do
    # Handle cancel action

  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :employee_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp encode_and_write_cookie(conn, token, user_id) do
    encoded_token = Base.encode64(token)
    IO.inspect(encoded_token)
    # put_resp_cookie(conn, key, value, opts \\ [])
    put_resp_cookie(conn, "turnStile-user-#{user_id}", encoded_token, @cookie_opts)
  end
  # defp delete_cookies(conn, token, user_id) do
  #   # delete_resp_cookie(conn, key, opts \\ [])
  # end
end
