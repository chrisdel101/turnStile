defmodule TurnStileWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller


  alias TurnStile.Patients
  alias TurnStile.Patients.UserToken
  alias TurnStileWeb.Router.Helpers, as: Routes

  @session_max_age_second UserToken.get_session_cookie_max_age_seconds()
  @expiration_cookie "_turn_stile_web_user_expiration" # used to control user session
  @expiration_me_options [sign: true, max_age: @session_max_age_seconds, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, params \\ %{}) do
    {token, _token_struct} = Patients.build_and_insert_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)
    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_expiration_cookie(token, params)
    |> redirect(to: signed_in_main_path(conn, user) || user_return_to )

  end
    defp maybe_write_expiration_cookie(conn, token, %{"expirtation" => "true"}) do
      put_resp_cookie(conn, @expiration_cookie, token, @expiration_me_options)
    end

  defp maybe_write_expiration_cookie(conn, _token, _params) do
    conn
  end

  @doc """
  Used for routes that require the user to be authenticated.

  Mean user has activated email token and now is in timed session - no login required
  """
  def require_authenticated_user(conn, _opts) do

    current_user = conn.assigns[:current_user]
    # IO.inspect(current_user, label: "current_user: require_authenticated_user")
    if conn.assigns[:current_user] do
      IO.puts("require_authenticated_user: passed")
      conn
    else
      IO.puts("require_authenticated_user: failed")
        conn
        |> put_flash(:info, "You're session is expired or you tried to access an authencated route.")
        |> maybe_store_return_to()
        |> redirect(to: "/")
    end
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Patients.delete_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      TurnStileWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@expiration_cookie)
    |> redirect(to: "/")
  end
  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_expired_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Patients.delete_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      TurnStileWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@expiration_cookie)

  end

  @doc """
  Authenticates the user by looking into the session
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    # IO.inspect(user_token, label: "USER TOKEN")
    user = user_token && Patients.get_user_by_session_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    # check for user token
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      {nil, conn}
    end
  end
  # call right after fetch_current_user
  def ensure_user_cookie_not_expired(conn, _opts) do
    # if logged in user
    if conn.assigns[:current_user] do
      conn = fetch_cookies(conn, signed: [@expirtation])
      if !Map.get(conn.cookies, "_turn_stile_web_user_expiration") do
        IO.puts("user expired")
        log_out_expired_user(conn)
      end
    end
    conn
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_main_path(conn, conn.assigns[:current_user]))
      |> halt()
    else
      conn
    end
  end


  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn


  defp signed_in_main_path(conn, current_user), do: Routes.user_session_path(conn, :new, Map.get(current_user, :id))
end
