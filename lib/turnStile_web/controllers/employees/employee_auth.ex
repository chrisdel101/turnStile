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
      |> redirect(to: "/")
    end

    # confirm this employee is in the correct organization
    is_in_organization? = Staff.check_employee_is_in_organization(employee, organization_id)
    IO.inspect(is_in_organization?, label: "is_in_organization?")

    if !is_in_organization? do
      conn
      |> put_flash(:error, "Invalid or Non-Existent Organization afflitiation")
      |> redirect(to: "/organizations/#{conn.path_params["id"]}")
      |> halt()
    end

    token = Staff.generate_employee_session_token(employee)
    employee_return_to = get_session(conn, :employee_return_to)
    # set these params in DB
    case set_employee_login_params(employee, organization_id) do
      {:ok, _employee} ->
        conn
        |> renew_session()
        |> put_session(:employee_token, token)
        |> put_session(:live_socket_id, "employee_sessions:#{Base.url_encode64(token)}")
        |> maybe_write_remember_me_cookie(token, params)
        |> redirect(to: employee_return_to || "/organizations/#{organization_id}")
      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: "/organizations/#{organization_id}")
    end
  end

  # logs in directly after being created - TODO diff to above
  def log_in_employee_on_create(conn, employee, organization_id, redirect_path, params \\ %{}) do
    # get org id from url
    # organization_id = Map.get(organization, "id") || Map.get(organization, :id)
    # IO.puts("organization_id")
    # IO.inspect(organization_id)
    # IO.inspect(organization)
    if !organization_id do
      conn
      # TODO - error msg here
      |> put_flash(:error, "An auto-login error occured. Please click login to manually login")
      |> redirect(to: Routes.page_path(conn, :index))
    end
    organization = TurnStile.Company.get_organization(organization_id)
    # stop login on non-existent organization
    if !organization do
      conn
      |> put_flash(:info, "That Organization doesn't exist. Try again.")
      |> redirect(to: Routes.organization_path(conn, :index))
    end

    token = Staff.generate_employee_session_token(employee)
    employee_return_to = get_session(conn, :employee_return_to)

    case set_employee_login_params(employee, organization_id) do
      {:ok, employee} ->
        IO.inspect(employee, label: "employee")
        conn
        |> renew_session()
        |> put_session(:employee_token, token)
        |> put_session(:live_socket_id, "employee_sessions:#{Base.url_encode64(token)}")
        |> maybe_write_remember_me_cookie(token, params)
        |> put_flash(:success, "#{params.flash}. You have been automatically logged in.")
        |> redirect(to: redirect_path || employee_return_to)

      {:error, error} ->
        IO.puts("Error in log_in_employee_on_create")
        IO.inspect(error)

        conn
        |> put_flash(:error, "Account created but login failed. Manual login reuqired")
        |> redirect(to: "organizations/#{organization_id}")
    end
  end
# group login settig calls together into one function
  defp set_employee_login_params(employee, organization_id) do
    case Staff.set_employee_role(employee, organization_id) do
      {:ok, employee} ->
        case Staff.set_is_logged_in(employee, organization_id) do
          {:ok, employee} ->
            {:ok, employee}
          {:error, error} ->
            {:error, error}
        end
      {:error, error} ->
        {:error, error}
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
    # IO.inspect(conn.assigns)
    # IO.inspect(get_session(conn, :employee_token))
    {employee_token, conn} = ensure_employee_token(conn)
    employee = employee_token && Staff.get_employee_by_session_token(employee_token)
    assign(conn, :current_employee, employee)
  end

  def get_employee_token(conn) do
    {employee_token, _conn} = ensure_employee_token(conn)
    employee_token
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
  Used for routes that require the employee to NOT be authenticated.
  """
  def redirect_if_employee_is_authenticated(conn, _opts) do
    # if logged in
    current_employee = conn.assigns[:current_employee]

    if current_employee do
      conn
      |> redirect(
        to: "/organizations/#{current_employee.current_organization_login_id}/employees/#{current_employee.id}/users"
      )
      |> halt()
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
        IO.puts("require_authenticated_employee: failed")

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

  checks if current_employee role above edit_employee_permissions_threshold; can visit pages that require it

  """
  def require_edit_access_employee(conn, _params) do
    current_employee = conn.assigns[:current_employee]
    IO.puts("require_edit_access_employee")

    if !current_employee do
      handle_missing_employee(conn)
    else
      # conver role_value digit to int
      role_value = Utils.convert_to_int(current_employee.role_value_on_current_organization)

      if role_value && (role_value <= EmployeePermissionThresholds.edit_employee_permissions_threshold()) do
        IO.puts("require_edit_access_employee: has edit access")
        conn
      else
        handle_insufficent_access(conn)
      end
    end
  end

  @doc """
  PLUG used in router
  Used for routes that require employee to have edit_access

  checks if current_employee role above edit_employee_permissions_threshold; can visit pages that require it

  """
  def require_register_access_employee(conn, _params) do
    current_employee = conn.assigns[:current_employee]
    IO.puts("require_register_access_employee")
    IO.inspect(current_employee)

    if !current_employee do
      handle_missing_employee(conn)
    else
      # conver role_value digit to int
      role_value = Utils.convert_to_int(current_employee.role_value_on_current_organization)

      if role_value && (role_value <= EmployeePermissionThresholds.register_employee_permissions_threshold()) do
        IO.puts("require_register_access_employee: has register access")
        conn
      else
        handle_insufficent_access(conn)
      end
    end
  end
  @doc """
  require_is_admin_employee
  PLUG used in router
  Used for routes that require employee to be admin or greater

  -checks if current_employee is above is_admin_employee_threshold; can visit pages that require it
  -used for employee show pages
  """
  def require_is_admin_employee(conn, _params) do
    current_employee = conn.assigns[:current_employee]
    IO.puts("require_is_admin_employee")
    IO.inspect(current_employee)

    if !current_employee do
      handle_missing_employee(conn)
    else
      # conver role_value digit to int
      role_value = Utils.convert_to_int(current_employee.role_value_on_current_organization)

      if role_value && (role_value <= EmployeePermissionThresholds.is_admin_employee_threshold()) do
        IO.puts("require_is_admin_employee: is_admin access")
        conn
      else
        handle_insufficent_access(conn)
      end
    end
  end

  # check current employee has greater-equal persmissions to register
  def has_employee_register_permissions?(conn, employee_params_to_register) do
    # check employee trying to edit
    current_employee = conn.assigns[:current_employee]
    # IO.inspect(current_employee)
    if !current_employee do
      false
    else
      # check if owner; owner has full access
      if current_employee.role_on_current_organization ===
        EmployeeRolesMap.get_permission_role("OWNER") do
        # IO.inspect("owner perms")
        true
      else
        current_user_permission = current_employee.role_value_on_current_organization

        registrant_role_value =
          Map.get(employee_params_to_register, "role_on_current_organization") ||
            Map.get(employee_params_to_register, :role_on_current_organization)
        # current must be equal to register; both are digit strings
        if current_user_permission <=
             registrant_role_value do
          true
        else
          false
        end
      end
    end
  end

  def has_employee_register_permissions?(_conn, employee_params_to_register, current_employee) do
    # IO.inspect(current_employee)
    if !current_employee do
      false
    else
      # check if owner; owner has full access
      if current_employee.role_on_current_organization ===
        EmployeeRolesMap.get_permission_role("OWNER") do
        # IO.inspect("owner perms")
        true
      else
        current_user_permission = current_employee.role_value_on_current_organization

        registrant_role_value =
          Map.get(employee_params_to_register, "role_on_current_organization") ||
            Map.get(employee_params_to_register, :role_on_current_organization)
        # current must be equal to register; both are digit strings
        if current_user_permission <=
             registrant_role_value do
          true
        else
          false
        end
      end
    end
  end

  @doc """
  check current employee has greater-equal persmissions to edit
  -used in employee controller: update
  """
  def has_employee_edit_permissions?(conn, employee_struct, _params \\ %{}) do
    # check employee trying to edit
    current_employee = conn.assigns[:current_employee]
    # IO.inspect(employee_struct)

    if !current_employee do
      false
    else
      # check if owner; owner has full access
      if Utils.convert_to_int(current_employee.role_value_on_current_organization) ===
        EmployeeRolesMap.get_permission_role("OWNER") do
        true
      else
        current_user_permission = current_employee.role_value_on_current_organization

        registrant_role_value = handle_get_role_value(conn, employee_struct)

        IO.inspect(current_user_permission, label: "current_user_permission")

        IO.inspect(registrant_role_value, label: "registrant_role_value")
        # current must be equal to register; both are digit strings
        if current_user_permission <
             registrant_role_value do
          true
        else
          false
        end
      end
    end
  end
  # same as edit but reneamed for clarity
  def has_employee_delete_permissions?(conn, employee_struct) do
    has_employee_edit_permissions?(conn, employee_struct)
  end
  # check current employee has user-add permissions
  def has_user_add_permissions?(conn) do
    current_employee = conn.assigns[:current_employee]
    if !current_employee do
      false
    else
      if Utils.convert_to_int(current_employee.role_value_on_current_organization) <=
        EmployeePermissionThresholds.add_user_permissions_threshold() do
        true
      else
        false
      end
    end
  end
  def has_user_add_permissions?(_socket, current_employee) do
    if !current_employee do
      false
    else
      if Utils.convert_to_int(current_employee.role_value_on_current_organization) <=
        EmployeePermissionThresholds.add_user_permissions_threshold() do
        true
      else
        false
      end
    end
  end
  # check current employee has user-add permissions
  def has_user_edit_permissions?(conn) do
    current_employee = conn.assigns[:current_employee]
    if !current_employee do
      false
    else
      if Utils.convert_to_int(current_employee.role_value_on_current_organization) <=
        EmployeePermissionThresholds.edit_user_permissions_threshold() do
        true
      else
        false
      end
    end
  end
  def has_user_edit_permissions?(_socket, current_employee) do
    if !current_employee do
      false
    else
      if Utils.convert_to_int(current_employee.role_value_on_current_organization) <=
        EmployeePermissionThresholds.edit_user_permissions_threshold() do
        true
      else
        false
      end
    end
  end

  def has_user_delete_permissions?(_socket, current_employee) do
    if !current_employee do
      false
    else
      if Utils.convert_to_int(current_employee.role_value_on_current_organization) <=
        EmployeePermissionThresholds.delete_user_permissions_threshold() do
        true
      else
        false
      end
    end
  end
  # sets user to inactive - removes from the page
  def has_user_remove_permissions?(_socket, current_employee) do
    if !current_employee do
      false
    else
      if Utils.convert_to_int(current_employee.role_value_on_current_organization) <=
        EmployeePermissionThresholds.remove_user_permissions_threshold() do
        true
      else
        false
      end
    end
  end

  def has_alert_send_permissions?(_socket, current_employee) do
    if !current_employee do
      false
    else
      if Utils.convert_to_int(current_employee.role_value_on_current_organization) <=
        EmployeePermissionThresholds.send_alert_permissions_threshold() do
        true
      else
        false
      end
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :employee_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp handle_missing_employee(conn) do
    IO.puts("handle_missing_employee: no current_employee")
    # redirect to index
    conn
    |> maybe_store_return_to()
    |> redirect(to: Routes.page_path(conn, :index))
    |> halt()
  end

  defp handle_get_role_value(conn, employee) do
    current_employee = conn.assigns[:current_employee]

    # IO.inspect(employee, label: "handle_role _ahandle_get_role_value: employee")
    # check if role_value
    cond do
      Map.get(employee, :role_value_on_current_organization) ->
          employee.role_value_on_current_organization
      Map.get(employee, :role_on_current_organization) ->
          role = employee.role_on_current_organization
          EmployeeRolesMap.get_permission_role_value(String.upcase(role))
      true ->
        role = TurnStile.Roles.get_employee_role_in_organization(employee.id, current_employee.current_organization_login_id)
        if role do
          role.value
        else
          IO.puts("handle_get_role_value: error getting role")
          nil
        end
    end

  end

  defp handle_insufficent_access(conn) do
    IO.inspect("handle_insufficent_access: insufficient permissions")
    IO.inspect(conn.assigns[:current_employee])

    current_organization_login_id =
      Map.get(conn.assigns[:current_employee], :current_organization_login_id, nil)

    conn
    |> put_flash(:error, "Insufficient permissions to access this page.")
    # |> maybe_store_return_to()
    |> redirect(to: Routes.organization_path(conn, :show, current_organization_login_id))
    |> halt()
  end
end
