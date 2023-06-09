defmodule TurnStileWeb.EmployeeSettingsController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    current_employee = conn.assigns.current_employee
    if !current_employee do
      conn
      |> put_flash(:error, "You must be logged in to access this page")
      |> redirect(to: "/")
    end
    changeset = Staff.change_employee(current_employee)
    render(conn, "edit.html", changeset: changeset)
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "employee" => employee_params} = params
    employee = conn.assigns.current_employee
    IO.inspect(employee.organization_id)
    case Staff.apply_employee_email(employee, password, employee_params) do
      {:ok, applied_employee} ->
        Staff.deliver_update_email_instructions(
          applied_employee,
          employee.email,
          &Routes.employee_settings_url(conn, :confirm_email, employee.organization_id, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.employee_settings_path(conn, :edit, employee.organization_id))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "employee" => employee_params} = params
    employee = conn.assigns.current_employee

    case Staff.update_employee_password(employee, password, employee_params) do
      {:ok, employee} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:employee_return_to, Routes.employee_settings_path(conn, :edit, employee.organization_id))
        |> EmployeeAuth.log_in_employee(employee)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Staff.update_employee_email(conn.assigns.current_employee, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.employee_settings_path(conn, :edit, conn.assigns.current_employee.organization_id))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.employee_settings_path(conn, :edit, conn.assigns.current_employee.organization_id))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    employee = conn.assigns.current_employee

    conn
    |> assign(:email_changeset, Staff.change_employee_email(employee))
    |> assign(:password_changeset, Staff.change_employee_password(employee))
  end
end
