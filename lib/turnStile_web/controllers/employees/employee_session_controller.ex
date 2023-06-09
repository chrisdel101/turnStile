defmodule TurnStileWeb.EmployeeSessionController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth

  # redirect to org sign in page
  def new(conn, _params) do
    redirect(conn, to: "/organizations/#{conn.path_params["id"]}")
  end

  def create(conn, %{"employee" => employee_params}) do
    %{"email" => email, "password" => password} = employee_params
    if employee = Staff.get_employee_by_email_and_password(email, password) do
      # set organization fields
      organization_id = Map.get(conn.path_params, "id") ||  Map.get(conn.path_params, :id)
      Staff.set_employee_role(employee, organization_id)
      Staff.set_is_logged_in(employee)
      EmployeeAuth.log_in_employee(conn, employee, employee_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.

      conn
      |> put_flash(:error, "Invalid email or password. Try again")
      |> redirect(to: "/organizations/#{conn.path_params["id"]}")
    end
  end

  def delete(conn, _params) do
    current_employee = conn.assigns[:current_employee]
    Staff.unset_is_logged_in(current_employee)
    Staff.unset_employee_role(current_employee)
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> EmployeeAuth.log_out_employee()
  end
end
