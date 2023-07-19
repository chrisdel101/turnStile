defmodule TurnStileWeb.UserConfirmationController do
  use TurnStileWeb, :controller

  alias TurnStile.Patients
  alias TurnStile.Patients.User
  alias TurnStile.Patients.UserToken

  def confirm(conn, %{"id" => alert_id, "token" => token}) do
      x  = Patients.confirm_user(token)
      IO.inspect(x, label: "xxxx")
      # do
      #   {:ok, user} ->
      #     IO.puts("YEAHYEAH")

      #   {:error, %Ecto.Changeset{} = changeset} ->
      #     conn
      #     |> put_flash(:error, "Error confirming password.")
      #     |> render("new.html", changeset: changeset)
      # end

  end

  # TODO- not working - unsure when employee + PW are coming from
  # Do not log in the employee after confirmation to avoid a
  # leaked token giving the employee access to the account.
  def update(conn, params) do
    IO.inspect(params)
    %{"token" => token, "id" => organization_id} =
      %{
        "employee" => %{
          "password" => password,
          "password_confirmation" => password_confirmation
        }
      } = params
    current_employee = conn.assigns[:current_employee]

    if current_employee do
      IO.puts("HERE update current_employee")
      # check confirm token is NOT same as logged in
      current_token = EmployeeAuth.get_employee_token(conn)

      if current_token !== token do
        IO.puts(
          "Invalid employee confirmation action. Current session does not match confirmation token"
        )

        conn
        |> put_flash(
          :error,
          "Employee confirmation link is invalid, expired, or does not match current user."
        )
        |> redirect(to: "/")
        |> halt()
      end
    end

    # check link has valid token
    case Staff.confirm_employee(token) do
      {:ok, employee} ->
        IO.puts("YEAHYEAH")

        case Staff.update_employee_password(employee, "password", %{
               "password" => password,
               "password_confirmation" => password_confirmation
             }) do
          {:ok, employee} ->
            if System.get_env("EMPLOYEE_CONFIRM_AUTO_LOGIN") === "true" do
              params = %{flash: "Account confirmed."}

              conn
              |> EmployeeAuth.log_in_employee_on_create(
                employee,
                organization_id,
                Routes.organization_path(conn, :show, organization_id, %{
                  "emptyParams" => true,
                  "paramsKey" => "org_params"
                }),
                params
              )

              # require manual login
            else

              conn
              |> put_flash(:info, "Employee confirmed successfully.")
              |> redirect(to: "/")
            end

          {:error, %Ecto.Changeset{} = changeset} ->
            changeset = %{changeset | action: :insert}
            conn
            # IO.puts("ERRORERRORERROR")
            # IO.inspect(changeset)
            |>
            render("setup.html", changeset: changeset, organization_id: organization_id, token: token)
            # IO.puts("ERRORERRORERROR")
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
