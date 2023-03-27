defmodule TurnStileWeb.EmployeeSettingsController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "employee" => admin_params} = params
    employee = conn.assigns.current_admin

    case Staff.apply_admin_email(employee, password, admin_params) do
      {:ok, applied_admin} ->
        Staff.deliver_update_email_instructions(
          applied_admin,
          employee.email,
          &Routes.admin_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.admin_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "employee" => admin_params} = params
    employee = conn.assigns.current_admin

    case Staff.update_admin_password(employee, password, admin_params) do
      {:ok, employee} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:admin_return_to, Routes.admin_settings_path(conn, :edit))
        |> EmployeeAuth.log_in_admin(employee)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Staff.update_admin_email(conn.assigns.current_admin, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.admin_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.admin_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    employee = conn.assigns.current_admin

    conn
    |> assign(:email_changeset, Staff.change_admin_email(employee))
    |> assign(:password_changeset, Staff.change_admin_password(employee))
  end
end
