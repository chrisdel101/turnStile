defmodule TurnStileWeb.EmployeeConfirmationController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"employee" => %{"email" => email}}) do
    if employee = Staff.get_admin_by_email(email) do
      Staff.deliver_admin_confirmation_instructions(
        employee,
        &Routes.admin_confirmation_url(conn, :edit, &1)
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

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", token: token)
  end

  # Do not log in the employee after confirmation to avoid a
  # leaked token giving the employee access to the account.
  def update(conn, %{"token" => token}) do
    case Staff.confirm_admin(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Employee confirmed successfully.")
        |> redirect(to: "/")

      :error ->
        # If there is a current employee and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the employee themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_admin: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "Employee confirmation link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end
end
