defmodule TurnStileWeb.EmployeeConfirmationController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStileWeb.EmployeeAuth

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"employee" => %{"email" => email}}) do
    if employee = Staff.get_employee_by_email(email) do
      Staff.deliver_employee_confirmation_instructions(
        employee,
        &Routes.employee_confirmation_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: "/")
  end

  # comes from email tokenized URL
  def edit(conn, %{"token" => token}) do
    # get org id from tokenized URL
    organization_id = Map.get(conn.params,"id")
    render(conn, "edit.html", id: organization_id, token: token)
  end

  # Do not log in the employee after confirmation to avoid a
  # leaked token giving the employee access to the account.
  def update(conn, %{"token" => token, "id"=> organization_id}) do
    case Staff.confirm_employee(token) do
      {:ok, employee} ->
        if System.get_env("EMPLOYEE_CONFIRM_AUTO_LOGIN") === "true" do
          IO.inspect("YYYYYY")
          params = %{flash: "Organization Successfully created"}
          conn
          |> EmployeeAuth.log_in_employee_on_create(employee, organization_id, Routes.organization_path(conn, :show, organization_id, %{"emptyParams" => true, "paramsKey" => "org_params"}), params)
        # require manual login
        else
          IO.inspect("XXXXXXX")
          conn
          |> put_flash(:info, "Employee confirmed successfully.")
          |> redirect(to: "/")
        end

      :error ->
        # If there is a current employee and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the employee themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_employee: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "Employee confirmation link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end
end
