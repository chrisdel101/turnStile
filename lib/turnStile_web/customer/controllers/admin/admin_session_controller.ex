defmodule TurnStileWeb.EmployeeSessionController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil, id: conn.path_params["id"])
  end

  def create(conn, %{"employee" => admin_params}) do
    %{"email" => email, "password" => password} = admin_params
    if employee = Staff.get_admin_by_email_and_password(email, password) do
      EmployeeAuth.log_in_admin(conn, employee, admin_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.

      conn
      |> put_flash(:error, "Invalid email or password. Try again")
      |> redirect(to: "/organizations/#{conn.path_params["id"]}")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> EmployeeAuth.log_out_admin()
  end
end
