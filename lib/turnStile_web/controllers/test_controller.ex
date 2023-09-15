defmodule TurnStileWeb.TestController do
  use TurnStileWeb, :controller
  # alias TurnStileWeb.EmployeeRegistrationController
  alias TurnStile.Staff
  # alias TurnStile.Company
  # alias TurnStile.Company.Organization
  # alias TurnStileWeb.EmployeeAuth
  alias TurnStile.Staff.Employee

  def employee_register_page(conn, params) do
    _current_employee = conn.assigns[:current_employee]
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
         conn.assigns[:route_type] === RouteTypesMap.get_route_type_value("TEST") do
      conn = assign(conn, :current_employee, current_employee)
      # IO.inspect(conn)
      conn
    else
      conn
    end
  end
  def get_fake_triage_json(conn, _opts) do
    triage_data = %{
      time_per_patient: 30,
      ordered_query: [
        %{
          "id" => 22,
          "last_name" => "Sam",
          "first_name" => "Smith",
          "health_number" => "33221123",
        },
        %{
          "id" => 33,
          "last_name" => "Schmo",
          "first_name" => "Joe",
          "health_number" => "9999",
        },
        %{
          "id" => 22,
          "last_name" => "Tony",
          "first_name" => "Kannan",
          "health_number" => "12442",
        },
        %{
          "id" => 443,
          "last_name" => "Sam",
          "first_name" => "Johnson",
          "health_number" => "112232",
        },
        %{
          "id" => 1111,
          "last_name" => "Joe4",
          "first_name" => "Schmoe",
          "health_number" => "1212",
        }
      ]
    }
    conn
    |> put_view(TurnStileWeb.JsonView)
    |> render("triage.json", data: TurnStile.Utils.convert_map_to_json(triage_data))
  end

end
