defmodule TurnStileWeb.EmployeeSettingsControllerTest do
  use TurnStileWeb.ConnCase, async: true

  alias TurnStile.Staff
  import TurnStile.StaffFixtures

  setup :register_and_log_in_employee

  describe "GET /employees/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.employee_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if employee is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.employee_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.employee_session_path(conn, :new)
    end
  end

  describe "PUT /employees/settings (change password form)" do
    test "updates the employee password and resets tokens", %{conn: conn, employee: employee} do
      new_password_conn =
        put(conn, Routes.employee_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_employee_password(),
          "employee" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.employee_settings_path(conn, :edit)
      assert get_session(new_password_conn, :employee_token) != get_session(conn, :employee_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Staff.get_employee_by_email_and_password(employee.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.employee_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "employee" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :employee_token) == get_session(conn, :employee_token)
    end
  end

  describe "PUT /employees/settings (change email form)" do
    @tag :capture_log
    test "updates the employee email", %{conn: conn, employee: employee} do
      conn =
        put(conn, Routes.employee_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_employee_password(),
          "employee" => %{"email" => unique_employee_email()}
        })

      assert redirected_to(conn) == Routes.employee_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert Staff.get_employee_by_email(employee.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.employee_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "employee" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /employees/settings/confirm_email/:token" do
    setup %{employee: employee} do
      email = unique_employee_email()

      token =
        extract_employee_token(fn url ->
          Staff.deliver_update_email_instructions(%{employee | email: email}, employee.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the employee email once", %{conn: conn, employee: employee, token: token, email: email} do
      conn = get(conn, Routes.employee_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.employee_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute Staff.get_employee_by_email(employee.email)
      assert Staff.get_employee_by_email(email)

      conn = get(conn, Routes.employee_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.employee_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, employee: employee} do
      conn = get(conn, Routes.employee_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.employee_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Staff.get_employee_by_email(employee.email)
    end

    test "redirects if employee is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.employee_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.employee_session_path(conn, :new)
    end
  end
end
