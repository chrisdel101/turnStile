defmodule TurnStileEmployeeRegistrationControllerTest do
  use TurnStileWeb.ConnCase, async: true

  import TurnStile.EmployeeFixtures

  describe "GET /employees/register" do
    test "renders registration page", %{conn: conn} do
      organization_id = 1 # add random id to make it work
      conn = get(conn, Routes.employee_registration_path(conn, :new, organization_id))
      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "Log in</a>"
      assert response =~ "Register</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      organization_id = 1 # add random id to make it work
      conn = conn |> log_in_employee(employee_fixture()) |> get(Routes.employee_registration_path(conn, :new, organization_id))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST organizations/:id/employees/register" do
    @tag :capture_log
    test "creates account and logs the employee in", %{conn: conn} do
      email = unique_employee_email()
      organization_id = 1 # add random id to make it work
      conn =
        post(conn, Routes.employee_registration_path(conn, :create, organization_id), %{
          "employee" => merge_employee_attributes(email: email)
        })

      assert get_session(conn, :employee_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ email
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "render errors for invalid data", %{conn: conn} do
      organization_id = 1 # add random id to make it work
      conn =
        post(conn, Routes.employee_registration_path(conn, :create, organization_id), %{
          "employee" => %{"email" => "with spaces", "password" => "too short"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
    end
  end
end
