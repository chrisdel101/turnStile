defmodule TurnStileWeb.EmployeeAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias TurnStile.Staff
  alias TurnStileWeb.Router.Helpers, as: Routes

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in EmployeeToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_turn_stile_web_employee_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the employee in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_employee(conn, employee, params \\ %{}) do
    # get org id from url
    organization_id = Map.get(conn.path_params, "id") ||  Map.get(conn.path_params, :id)
    if !organization_id do
      conn
      # TODO - error msg here
      |> put_flash(:error, "An Organization ID error ocurred. Make sure it exists.")
      |> redirect(to: Routes.organization_path(conn, :show))
    end
    # confirm this employee is in the correct organization
    is_in_organization? = Staff.check_employee_is_in_organization(employee,organization_id)
    if !is_in_organization? do
      conn
      |> put_flash(:error, "Invalid or Non-Existent Organization afflitiation")
      |> redirect(to: "/organizations/#{conn.path_params["id"]}")
      |> halt()
    end
    token = Staff.generate_employee_session_token(employee)
    employee_return_to = get_session(conn, :employee_return_to)
    conn
    |> renew_session()
    |> put_session(:employee_token, token)
    |> put_session(:live_socket_id, "employee_sessions:#{Base.url_encode64(token)}")
    |> put_session(:current_organization_id_str, organization_id)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: "/organizations/#{organization_id}/employees/#{employee.id}/users" || employee_return_to )
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
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
  Logs the employee out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_employee(conn) do
    employee_token = get_session(conn, :employee_token)
    employee_token && Staff.delete_session_token(employee_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      TurnStileWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> delete_session(:organization_id_str)
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the employee by looking into the session
  and remember me token.
  """
  def fetch_current_employee(conn, _opts) do
    {employee_token, conn} = ensure_employee_token(conn)
    employee = employee_token && Staff.get_employee_by_session_token(employee_token)
    assign(conn, :current_employee, employee)
  end

  # gets signed in org from sessions, adds to conn each req
  def fetch_current_organization(conn, _opts) do
    # IO.inspect("fetch_current_organization")
    current_organization_id_str = get_session(conn, :current_organization_id_str) || get_session(conn, "current_organization_id_str")
    # IO.inspect(current_organization_id_str)
    conn =  assign(conn,:current_organization_id_str,current_organization_id_str)
    IO.inspect("fetch_current_organization")
    IO.inspect(conn.params)
    # IO.inspect(conn)
    IO.inspect(get_session(conn))
    conn
  end

  defp ensure_employee_token(conn) do
    if employee_token = get_session(conn, :employee_token) do
      {employee_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if employee_token = conn.cookies[@remember_me_cookie] do
        {employee_token, put_session(conn, :employee_token, employee_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the employee to not be authenticated.
  """
  def redirect_if_employee_is_authenticated(conn, _opts) do
    # if logged in
    current_employee = conn.assigns[:current_employee]
    current_organization_id_str = conn.assigns[:current_organization_id_str]
    if current_employee do
      # if owner/employee - don't redirect from registartion
      # if (current_employee.role != "owner" or current_employee.role != "employee") and
      #      List.last(conn.path_info) != "register" do
        conn
        |> redirect(to: "/organizations/#{current_organization_id_str}/employees/#{current_employee.id}/users")
        |> halt()
      # else
        # conn
      # end
    else
      conn
    end
  end

  @doc """
  Used for routes that require the employee to be authenticated.

  If you want to enforce the employee email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_employee(conn, _opts) do
    id = conn.path_params["id"]
    if conn.assigns[:current_employee] do
      conn
    else
      if id do
        conn
        |> put_flash(:error, "You must log in to access this page.")
        |> maybe_store_return_to()
        |> redirect(to: Routes.employee_session_path(conn, :new, id))
        |> halt()
      else
        # handle no ID case - terrible syntax but nicer kept breaking
        conn
        |> put_flash(:info, "You tried to access a authencated route.")
        |> maybe_store_return_to()
        |> redirect(to: "/")
        |> halt()
      end
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :employee_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
  # plug

end
