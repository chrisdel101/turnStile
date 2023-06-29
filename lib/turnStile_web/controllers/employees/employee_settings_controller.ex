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

  def update(conn, %{"action" => "update_name"} = params) do
    %{"employee" => employee_params} = params
    current_employee = conn.assigns[:current_employee]
    IO.inspect(employee_params, label: "Employee.update")
    IO.inspect(current_employee, label: "Employee.update")
    case Staff.update_employee(current_employee, employee_params) do
      {:ok, _applied_employee} ->
        conn
        |> put_flash(
          :success,
          "Employee details updated."
        )
        |> redirect(to: Routes.employee_settings_path(conn, :edit, current_employee.current_organization_login_id))

      {:error, changeset} ->
        conn
        |>
        render("edit.html", changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "employee" => employee_params} = params
    current_employee = conn.assigns[:current_employee]
    # IO.inspect(params)
    case Staff.apply_employee_email(current_employee, password, employee_params) do
      {:ok, applied_employee} ->
        Staff.deliver_update_email_instructions(
          applied_employee,
          current_employee.email,
          &Routes.employee_settings_url(conn, :confirm_email, current_employee.current_organization_login_id, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.employee_settings_path(conn, :edit, current_employee.current_organization_login_id))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset, changeset: Staff.change_employee(current_employee))
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "employee" => employee_params} = params
    current_employee = conn.assigns[:current_employee]

    case Staff.update_employee_password(current_employee, password, employee_params) do
      {:ok, employee} ->
        conn
        |> put_flash(:success, "Password updated successfully.")
        |> put_session(:employee_return_to, Routes.employee_settings_path(conn, :edit, employee.current_organization_login_id))
        |> EmployeeAuth.log_in_employee(employee)

      {:error, changeset} ->
        IO.inspect(changeset, label: "changeset")
        render(conn, "edit.html", password_changeset: changeset, changeset: Staff.change_employee(current_employee))
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Staff.update_employee_email(conn.assigns.current_employee, token) do
      :ok ->
        conn
        |> put_flash(:success, "Email changed successfully.")
        |> redirect(to: Routes.employee_settings_path(conn, :edit, case conn.assigns.current_employee do
          %{current_organization_login_id: org_id} -> org_id
          _ -> 0
        end))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.employee_settings_path(conn, :edit, case conn.assigns.current_employee do
          %{current_organization_login_id: org_id} -> org_id
          _ -> 0
        end))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    employee = conn.assigns.current_employee

    conn
    |> assign(:email_changeset, Staff.change_employee_email(employee))
    |> assign(:password_changeset, Staff.change_employee_password(employee))
  end
end
