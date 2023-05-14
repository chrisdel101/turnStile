defmodule TurnStileWeb.EmployeeSessionControllerTest do
  use TurnStileWeb.ConnCase, async: true

  import TurnStile.EmployeeFixtures

  setup do
    %{employee: employee_fixture()}
  end

  describe "GET /employees/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.employee_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Register</a>"
      assert response =~ "Forgot your password?</a>"
    end

    test "redirects if already logged in", %{conn: conn, employee: employee} do
      conn = conn |> log_in_employee(employee) |> get(Routes.employee_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /employees/log_in" do
    test "logs the employee in", %{conn: conn, employee: employee} do
      conn =
        post(conn, Routes.employee_session_path(conn, :create), %{
          "employee" => %{"email" => employee.email, "password" => valid_employee_password()}
        })

      assert get_session(conn, :employee_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ employee.email
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "logs the employee in with remember me", %{conn: conn, employee: employee} do
      conn =
        post(conn, Routes.employee_session_path(conn, :create), %{
          "employee" => %{
            "email" => employee.email,
            "password" => valid_employee_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_turn_stile_web_employee_remember_me"]
      assert redirected_to(conn) == "/"
    end

    test "logs the employee in with return to", %{conn: conn, employee: employee} do
      conn =
        conn
        |> init_test_session(employee_return_to: "/foo/bar")
        |> post(Routes.employee_session_path(conn, :create), %{
          "employee" => %{
            "email" => employee.email,
            "password" => valid_employee_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, employee: employee} do
      conn =
        post(conn, Routes.employee_session_path(conn, :create), %{
          "employee" => %{"email" => employee.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /employees/log_out" do
    test "logs the employee out", %{conn: conn, employee: employee} do
      conn = conn |> log_in_employee(employee) |> delete(Routes.employee_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :employee_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the employee is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.employee_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :employee_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
