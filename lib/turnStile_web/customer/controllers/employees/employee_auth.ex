defmodule TurnStileWeb.EmployeeAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias TurnStile.Utils
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
    organization_id = Map.get(conn.path_params, "id") || Map.get(conn.path_params, :id)

    if !organization_id do
      conn
      # TODO - error msg here
      |> put_flash(:error, "An Organization ID error ocurred. Make sure it exists.")
      |> redirect(to: Routes.organization_path(conn, :show))
    end

    # confirm this employee is in the correct organization
    is_in_organization? = Staff.check_employee_is_in_organization(employee, organization_id)

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
    |> redirect(
      to: "/organizations/#{organization_id}/employees/#{employee.id}/users" || employee_return_to
    )
  end

  # logs in directly after being created - TODO diff to above
  def log_in_employee_on_create(conn, employee, organization_id, redirect_path, params \\ %{}) do
    # get org id from url
    # organization_id = Map.get(organization, "id") || Map.get(organization, :id)
    IO.puts("organization_id")
    IO.inspect(organization_id)
    # IO.inspect(organization)
    if !organization_id do
      conn
      # TODO - error msg here
      |> put_flash(:error, "An auto-login error occured. Please click login to manually login")
      |> redirect(to: Routes.page_path(conn, :index))
    end

    token = Staff.generate_employee_session_token(employee)
    employee_return_to = get_session(conn, :employee_return_to)

    case Staff.set_employee_role(employee, organization_id) do
      {:ok, employee} ->
        IO.puts("employee")
        IO.inspect(employee)
        Staff.set_is_logged_in(employee)

        conn
        |> renew_session()
        |> put_session(:employee_token, token)
        |> put_session(:live_socket_id, "employee_sessions:#{Base.url_encode64(token)}")
        |> put_session(:current_organization_id_str, organization_id)
        |> maybe_write_remember_me_cookie(token, params)
        |> put_flash(:success, "#{params.flash}. You have been automatically logged in.")
        |> redirect(to: redirect_path || employee_return_to)

      {:error, error} ->
        IO.puts("Error in log_in_employee_on_create")
        IO.inspect(error)

        conn
        |> put_flash(:error, "Account created but login failed. Manual login reuqired.")
        |> redirect(to: "organizations/#{organization_id}" || employee_return_to)
    end
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
    current_organization_id_str =
      get_session(conn, :current_organization_id_str) ||
        get_session(conn, "current_organization_id_str")

    # IO.inspect(current_organization_id_str)
    conn = assign(conn, :current_organization_id_str, current_organization_id_str)
    IO.inspect("fetch_current_organization")
    IO.inspect(conn)
    IO.inspect("session")
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
      |> redirect(
        to: "/organizations/#{current_organization_id_str}/employees/#{current_employee.id}/users"
      )
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

  @doc """
  Used for routes that require employee to have edit_access

  checks if current_employee role above edit_permissions_threshold; can visit pages that require it

  """
  def require_edit_access_employee(conn, _params) do
    current_employee = conn.assigns[:current_employee]
    IO.puts("require_edit_access_employee")
    IO.inspect(current_employee)

    if !current_employee do
      handle_missing_employee(conn)
    else
      # conver role_value digit to int
      role_value =
        Utils.convert_to_int(current_employee.role_value_on_current_organization)

      if role_value && role_value <= EmployeePermissionGroups.edit_permissions_threshold() do
        IO.puts("require_edit_access_employee: has edit access")
        conn
      else
        handle_insufficent_permissions(conn)
      end
    end
  end
  @doc """
  Used for routes that require employee to have edit_access

  checks if current_employee role above edit_permissions_threshold; can visit pages that require it

  """
  def require_register_access_employee(conn, _params) do
    current_employee = conn.assigns[:current_employee]
    IO.puts("require_register_access_employee")
    IO.inspect(current_employee)

    if !current_employee do
      handle_missing_employee(conn)
    else
      # conver role_value digit to int
      role_value =
        Utils.convert_to_int(current_employee.role_value_on_current_organization)

      if role_value && role_value <= EmployeePermissionGroups.register_permissions_threshold() do
        IO.puts("require_register_access_employee: has register access")
        conn
      else
        handle_insufficent_permissions(conn)
      end
    end
  end
  # check current employee has greater persmissions to edit
  def has_sufficient_update_permissions?(conn, employee_to_update) do
    # check employee trying to edit
    current_employee = conn.assigns[:current_employee]

    if !current_employee do
      false
    else
      if current_employee.role_value ===
           to_string(EmployeePermissionGroups.get_persmission_value("owner")) do
        # owner has full access
        true
      else
        current_user_permission =
          TurnStile.PermissionsUtils.get_employee_permissions_level(current_employee.role)

        # check level of user being createdd
        registrant_permissions =
          TurnStile.PermissionsUtils.get_employee_permissions_level(employee_to_update.role)

        # current must be LESS to edit
        if current_user_permission <
             registrant_permissions do
          true
        else
          false
        end
      end
    end
  end
  # check current employee has greater persmissions to edit
  def has_sufficient_register_permissions?(conn, employee_params_to_register) do
    # check employee trying to edit
    current_employee = conn.assigns[:current_employee]

    if !current_employee do
      false
    else
      # check if owner; owner has full access
      if current_employee.role_on_current_organization ===
           to_string(EmployeePermissionGroups.get_persmission_value("owner")) do
            true
      else
        current_user_permission =
          current_employee.role_value_on_current_organization
        registrant_role = Map.get(employee_params_to_register, "role_on_current_organization") || Map.get(employee_params_to_register, :role_on_current_organization)

         registrant_role_value = EmployeePermissionGroups.get_persmission_value(registrant_role)
        # current must be LESS to edit
        if         current_user_permission <
          registrant_role_value do
          true
        else
          false
        end
      end
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :employee_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp handle_missing_employee(conn) do
    IO.puts("handle_missing_employee: no current_employee")
    conn
    |> maybe_store_return_to()
    |> redirect(to: Routes.organization_employee_path(conn, :index, nil))
    |> halt()
  end
  defp handle_insufficent_permissions(conn) do
    IO.inspect("handle_insufficent_permissions: insufficient permissions")
    conn
    |> put_flash(:error, "Insufficient permissions to access this page.")
    |> maybe_store_return_to()
    |> redirect(to: Routes.organization_employee_path(conn, :index, nil))
    |> halt()
  end
end
