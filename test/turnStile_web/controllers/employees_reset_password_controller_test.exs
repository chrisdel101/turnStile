defmodule TurnStileWeb.AdminResetPasswordControllerTest do
  use TurnStileWeb.ConnCase, async: true

  alias TurnStile.Staff
  alias TurnStile.Repo
  import TurnStile.EmployeeFixtures

  setup do
    %{employee: employee_fixture()}
  end

  describe "GET /employees/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, Routes.employee_reset_password_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Forgot your password?</h1>"
    end
  end

  describe "POST /employees/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, employee: employee} do
      conn =
        post(conn, Routes.employee_reset_password_path(conn, :create), %{
          "employee" => %{"email" => employee.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Staff.EmployeeToken, employee_id: employee.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.employee_reset_password_path(conn, :create), %{
          "employee" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Staff.EmployeeToken) == []
    end
  end

  describe "GET /employees/reset_password/:token" do
    setup %{employee: employee} do
      token =
        extract_employee_token(fn url ->
          Staff.deliver_employee_reset_password_instructions(employee, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn = get(conn, Routes.employee_reset_password_path(conn, :edit, token))
      assert html_response(conn, 200) =~ "<h1>Reset password</h1>"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, Routes.employee_reset_password_path(conn, :edit, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end

  describe "PUT /employees/reset_password/:token" do
    setup %{employee: employee} do
      token =
        extract_employee_token(fn url ->
          Staff.deliver_employee_reset_password_instructions(employee, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, employee: employee, token: token} do
      conn =
        put(conn, Routes.employee_reset_password_path(conn, :update, token), %{
          "employee" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == Routes.employee_session_path(conn, :new)
      refute get_session(conn, :employee_token)
      assert get_flash(conn, :info) =~ "Password reset successfully"
      assert Staff.get_employee_by_email_and_password(employee.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, Routes.employee_reset_password_path(conn, :update, token), %{
          "employee" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Reset password</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, Routes.employee_reset_password_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end
end
