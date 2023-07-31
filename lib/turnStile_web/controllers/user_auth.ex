defmodule TurnStileWeb.UserAuth do
  use TurnStileWeb, :controller
  import Plug.Conn
  import Phoenix.Controller

  alias TurnStile.Patients
  alias TurnStile.Patients.UserToken
  alias TurnStileWeb.Router.Helpers, as: Routes

  @session_max_age_seconds UserToken.get_session_token_validity_seconds()
  # used to control user session
  @expiration_cookie "_turn_stile_web_user_expiration"
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

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_expiration_cookie(token, params)
  end

  # if set to true make sure to put ensure_user_cookie_not_expired in routuer plug pipeline - currently no used
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
    # current_user = conn.assigns[:current_user]
    # IO.inspect(conn.assigns[:current_user], label: "current_user: require_authenticated_user")
    if conn.assigns[:current_user] do
      conn
    else
      IO.puts("require_authenticated_user: failed")

      conn
      |> put_flash(
        :info,
        "You're session is expired or you tried to access an authencated route."
      )
      |> maybe_store_return_to()
      |> redirect(to: "/")
      |> halt()
    end
  end

  # if expired logs out user and redirects to index
  def require_non_expired_user_session(conn, _params) do
    if conn.assigns[:current_user] do
      handle_validate_session_token(conn)
    else
      conn
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
    |> redirect(to: Routes.page_path(conn, :index))
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
  - Checks for existence only; no expiration check here - keeping the flow simple
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_session_token(conn)
    # IO.inspect(user_token, label: "fetch_current_user USER TOKEN")
    # - queries for exists and valid
    user = user_token && Patients.confirm_user_session_token_exists(user_token)
    # IO.inspect(user, label: "fetch_current_user USER")
    assign(conn, :current_user, user)
  end

  # first run: looks up user by email token; should fail b/c no user in seesion yet
  defp ensure_user_session_token(conn) do
    # check for user token
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      {nil, conn}
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      IO.puts("Redirect if user is authenticated: redirecting")

      conn
      |> redirect(to: signed_in_main_path(conn, conn.assigns[:current_user]))
      |> halt()
    else
      IO.puts("Redirect if user is authenticated: not authenicated")
      conn
    end
  end

  def handle_validate_session_token(conn) do
    if conn.assigns[:current_user] do
      user_token = get_session(conn, :user_token)

      case user_token && Patients.confirm_user_session_token(user_token) do
        {:ok, _user} ->
          IO.puts("handle_validate_session_token: user session not expired")
          conn
        {nil, :not_found} ->
          IO.puts("handle_validate_session_token: user session error")
          conn
          |> put_flash(
            :info,
            "You're session has encountered a matching error. Contact your provider if you need a new link."
          )
          |> log_out_expired_user()
          |> redirect(to: Routes.page_path(conn, :index))
          |> halt()

        {:expired, user} ->
          IO.puts("handle_validate_session_token: user session expired")
          push_user_and_interface_updates(conn, user.id)
          conn
          |> put_flash(
            :info,
            "You're session has expired. Contact your provider again to receive a new link."
          )
          |> log_out_expired_user()
          |> redirect(to: Routes.page_path(conn, :index))
          |> halt()
      end
    else
      conn
    end
  end

  @doc """
  # handle_validate_email_token
  # - handles request if user if not logged yet
  # - if logged in user calls this redirect them to new/1
  # - else confirm email token + log in and redirect to new/1
  # - if not confirmed email send err val and redirect
  # - handles all cases of email token errors
  # - if email token expired sends status update to UI
  """
  def handle_validate_email_token(conn, %{"user_id" => user_id, "token" => encoded_token}) do
    current_user = conn.assigns[:current_user]

    if current_user do
      conn
      |> redirect(to: Routes.user_session_path(conn, :new, current_user.id))
    else
      # check URL encoded_token - match url to hashed-token in DB
      case Patients.confirm_user_email_token(encoded_token, user_id) do
        {:ok, user} ->
          # IO.inspect(user, label: "USER")
          conn
          # log in and set session token for future requests
          |> log_in_user(user)
          |> redirect(to: signed_in_main_path(conn, user) || get_session(conn, :user_return_to))

        {nil, :not_matched} ->
          # user does match but - url :id is not correct for user token
          IO.puts("user_auth: user not_matched: User param :id does not match the token user id")

          conn
          |> put_flash(
            :error,
            "Sorry, your URL link has errors. Verify it is correct and try again, or contact your provider for a new link."
          )
          |> redirect(to: "/")

        {nil, :not_found} ->
          # no users matching - b/c user session does not match any users
          IO.puts("user_auth:  not_found")

          conn
          |> put_flash(:error, "Sorry, your URL link is invalid.")
          |> redirect(to: "/")

        :invalid_input_token ->
          # error on func call - b/c user has a malfromed URL i.e. extra quote at end
          IO.puts("user_auth:  :invalid_input_token")

          conn
          |> put_flash(
            :error,
            "Sorry, your URL link contains errors and is invalid. Confirm it is correct and try again, or contact your provider for a new link."
          )
          |> redirect(to: "/")

        {nil, :expired} ->
          # valid request but expired - will be deleted on this call
          # fetch full user token struct
          {:ok, query} = UserToken.encoded_token_and_context_query(encoded_token, "confirm")
          user_token = TurnStile.Repo.one(query)
          # delete expirted token
          Patients.delete_email_token(user_token)
          IO.puts("user_auth:  token expired and deleted")
          # update user alert status
          push_user_and_interface_updates(conn, user_id)

          conn
          |> put_flash(
            :error,
            "Sorry, your link has expired. Contact your provider to resend a new link."
          )
          |> redirect(to: "/")
      end
    end
  end

  # push_user_and_interface_updates
  # - updates user alert status to EXPIRED
  # - calls Phoenix.PubSub.broadcast to send update to UI
  defp push_user_and_interface_updates(_conn, user_id) do
    # update user alert status
    user = Patients.get_user(user_id)

    {:ok, updated_user} =
      Patients.update_alert_status(user, UserAlertStatusTypesMap.get_user_status("EXPIRED"))

    # send respnse to update UI; match the DB status - opts pushes it to index liveView handler
    Phoenix.PubSub.broadcast(
      TurnStile.PubSub,
      PubSubTopicsMap.get_topic("STATUS_UPDATE"),
      %{user_alert_status: updated_user.user_alert_status}
    )
  end

  # is_user_session_exprired?
  # - checks if user token still valid
  # prev plug checked user exists
  defp is_user_session_exprired?(conn) do
    user_token = get_session(conn, :user_token)

    case user_token && Patients.confirm_user_session_token(user_token) do
      {:ok, _user} ->
        IO.puts("is_user_session_exprired: user session not expired")
        false

      {nil, :not_found} ->
        IO.puts("is_user_session_exprired: user session error")
        true

      {nil, :expired} ->
        IO.puts("is_user_session_exprired: user session expired")
        true
    end
  end

  # puts path like /user/:id as :user_return_to
  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  def signed_in_main_path(conn, current_user),
    do: Routes.user_session_path(conn, :new, Map.get(current_user, :id))
end
