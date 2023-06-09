defmodule TurnStileWeb.TestController do
  use TurnStileWeb, :controller
  # alias TurnStileWeb.EmployeeRegistrationController
  alias TurnStile.Staff
  # alias TurnStile.Company
  # alias TurnStile.Company.Organization
  # alias TurnStileWeb.EmployeeAuth
  alias TurnStile.Staff.Employee

  def employee_register_page(conn, params) do
    current_employee = conn.assigns[:current_employee]
    %{"id" => id} = params
    changeset = Staff.change_employee_registration(%Employee{})

    render(conn, TurnStileWeb.EmployeeRegistrationView, "new.html",
      organization_id: id,
      changeset: changeset
    )
  end

  def quick_register_employee(conn, params) do
    %{"id" => id} = params
    last_employee_added = Staff.list_all_employees() |> Enum.at(-1)

    if !last_employee_added do
      IO.puts("DB is emtpy. Add some users or seeds and re-run.")

      conn
      |> System.halt()
    end

    IO.inspect(last_employee_added)

    e = %{
      "employee" => %{
        "email" => "joe#{last_employee_added.id + 1}@schmo.com",
        "email_confirmation" => "joe#{last_employee_added.id + 1}@schmo.com",
        "first_name" => "Joe ",
        "last_name" => "Schmo",
        "password" => "password",
        "password_confirmation" => "password",
        "organization_id" => 1,
        "role_on_current_organization" => "admin"
      }
    }

    TurnStileWeb.EmployeeRegistrationController.create(conn, e)

    changeset = Staff.change_employee_registration(%Employee{})

    render(conn, TurnStileWeb.EmployeeRegistrationView, "new.html",
      organization_id: id,
      changeset: changeset
    )
  end

  def set_test_current_employee(conn, _params) do
    current_employee = TurnStile.Staff.get_employee(1)

    if Mix.env() == :test &&
         conn.assigns[:route_type] === RouteTypesEnum.get_route_type_value("TEST") do
      conn = assign(conn, :current_employee, current_employee)
      conn = assign(conn, :current_organization_id_str, "1")
      # IO.inspect(conn)
      conn
    else
      conn
    end
  end
end
