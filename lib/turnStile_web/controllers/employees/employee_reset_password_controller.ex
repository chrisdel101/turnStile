defmodule TurnStileWeb.EmployeeResetPasswordController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff

  plug :get_employee_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    organization_id = Map.get(conn.params,"id")
    render(conn, "new.html", organization_id: organization_id)
  end

  def create(conn, %{"employee" => %{"email" => email}}) do
    if employee = Staff.get_employee_by_email(email) do
      organization_id = Map.get(conn.params,"id")
      # IO.inspect(organization_id, label: "organization_id")
      Staff.deliver_employee_reset_password_instructions(
        employee,
        &Routes.employee_reset_password_url(conn, :edit, organization_id, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      conditional_flash_message(employee)
    )
    |> redirect(to: "/")
  end

  def edit(conn, _params) do
    organization_id = Map.get(conn.params,"id")
    render(conn, "edit.html", organization_id: organization_id, changeset: Staff.change_employee_password(conn.assigns.employee))
  end

  # Do not log in the employee after reset password to avoid a
  # leaked token giving the employee access to the account.
  # TODO:need better way to get get org id; getting from params in not secure
  def update(conn, %{"employee" => employee_params}) do
    organization_id = Map.get(conn.params,"id")
    case Staff.reset_employee_password(conn.assigns.employee, employee_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: Routes.employee_session_path(conn, :new, organization_id))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp get_employee_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if employee = Staff.get_employee_by_reset_password_token(token) do
      conn |> assign(:employee, employee) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: "/")
      |> halt()
    end
  end
  # tell user if their address exists based on env flag; default to not telling
  defp conditional_flash_message(employee) do
    case employee do
      nil ->
        true
        cond do
          System.get_env("EMPLOYEE_PASSWORD_RESET_EMAIL_FOUND_ALERT") == "true" ->
            "That email address was not found in our system. Please try a different email address."
          true -> # default message
            "If your email is in our system, you will receive instructions to reset your password shortly."
        end
      # is not nil
      _ ->
        cond do
          System.get_env("EMPLOYEE_PASSWORD_RESET_EMAIL_FOUND_ALERT") == "true" ->
            "Your address was found. You will receive instructions to reset your password shortly"
          true -> # default message
            "If your email is in our system, you will receive instructions to reset your password shortly."
        end
    end
  end
end
