defmodule TurnStileWeb.EmployeeAuthTest do
  use TurnStileWeb.ConnCase, async: true

  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth
  import TurnStile.EmployeeFixtures

  @remember_me_cookie "_turn_stile_web_employee_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, TurnStileWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{employee: employee_fixture(), conn: conn}
  end

  describe "log_in_employee/3" do
    test "stores the employee token in the session", %{conn: conn, employee: employee} do
      conn = EmployeeAuth.log_in_employee(conn, employee)
      assert token = get_session(conn, :employee_token)
      assert get_session(conn, :live_socket_id) == "employee_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert Staff.get_employee_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, employee: employee} do
      conn = conn |> put_session(:to_be_removed, "value") |> EmployeeAuth.log_in_employee(employee)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, employee: employee} do
      conn = conn |> put_session(:employee_return_to, "/hello") |> EmployeeAuth.log_in_employee(employee)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, employee: employee} do
      conn = conn |> fetch_cookies() |> EmployeeAuth.log_in_employee(employee, %{"remember_me" => "true"})
      assert get_session(conn, :employee_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :employee_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_employee/1" do
    test "erases session and cookies", %{conn: conn, employee: employee} do
      employee_token = Staff.generate_employee_session_token(employee)

      conn =
        conn
        |> put_session(:employee_token, employee_token)
        |> put_req_cookie(@remember_me_cookie, employee_token)
        |> fetch_cookies()
        |> EmployeeAuth.log_out_employee()

      refute get_session(conn, :employee_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute Staff.get_employee_by_session_token(employee_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "employee_sessions:abcdef-token"
      TurnStileWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> EmployeeAuth.log_out_employee()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if employee is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> EmployeeAuth.log_out_employee()
      refute get_session(conn, :employee_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_employee/2" do
    test "authenticates employee from session", %{conn: conn, employee: employee} do
      employee_token = Staff.generate_employee_session_token(employee)
      conn = conn |> put_session(:employee_token, employee_token) |> EmployeeAuth.fetch_current_employee([])
      assert conn.assigns.current_employee.id == employee.id
    end

    test "authenticates employee from cookies", %{conn: conn, employee: employee} do
      logged_in_conn =
        conn |> fetch_cookies() |> EmployeeAuth.log_in_employee(employee, %{"remember_me" => "true"})

      employee_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> EmployeeAuth.fetch_current_employee([])

      assert get_session(conn, :employee_token) == employee_token
      assert conn.assigns.current_employee.id == employee.id
    end

    test "does not authenticate if data is missing", %{conn: conn, employee: employee} do
      _ = Staff.generate_employee_session_token(employee)
      conn = EmployeeAuth.fetch_current_employee(conn, [])
      refute get_session(conn, :employee_token)
      refute conn.assigns.current_employee
    end
  end

  describe "redirect_if_employee_is_authenticated/2" do
    test "redirects if employee is authenticated", %{conn: conn, employee: employee} do
      conn = conn |> assign(:current_employee, employee) |> EmployeeAuth.redirect_if_employee_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "does not redirect if employee is not authenticated", %{conn: conn} do
      conn = EmployeeAuth.redirect_if_employee_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_employee/2" do
    test "redirects if employee is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> EmployeeAuth.require_authenticated_employee([])
      assert conn.halted
      assert redirected_to(conn) == Routes.employee_session_path(conn, :new)
      assert get_flash(conn, :error) == "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> EmployeeAuth.require_authenticated_employee([])

      assert halted_conn.halted
      assert get_session(halted_conn, :employee_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> EmployeeAuth.require_authenticated_employee([])

      assert halted_conn.halted
      assert get_session(halted_conn, :employee_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> EmployeeAuth.require_authenticated_employee([])

      assert halted_conn.halted
      refute get_session(halted_conn, :employee_return_to)
    end

    test "does not redirect if employee is authenticated", %{conn: conn, employee: employee} do
      conn = conn |> assign(:current_employee, employee) |> EmployeeAuth.require_authenticated_employee([])
      refute conn.halted
      refute conn.status
    end
  end
end
