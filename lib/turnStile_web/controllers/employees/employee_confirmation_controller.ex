defmodule TurnStileWeb.EmployeeConfirmationController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStile.Staff.Employee
  alias TurnStileWeb.EmployeeAuth

  def new(conn, _params) do
    render(conn, "new.html")
  end

  # comes from email tokenized URL
  def setup(conn, %{"token" => token}) do
    # get org id from tokenized URL
    changeset = Staff.change_employee_password(%Employee{}, %{}, true)
    organization_id = Map.get(conn.params, "id")

    render(conn, "setup.html",
      organization_id: organization_id,
      token: token,
      changeset: changeset
    )
  end

  # TODO- not working - unsure when employee + supossed to be are coming from below
  # ******
  # Do not log in the employee after confirmation to avoid a
  # leaked token giving the employee access to the account.
  def update(conn, params) do
    %{"token" => token, "id" => organization_id} =
      %{
        "employee" => %{
          "password" => password,
          "password_confirmation" => password_confirmation
        }
      } = params

    current_employee = conn.assigns[:current_employee]

    if current_employee do
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
            changeset = %{changeset | action: :update}

            conn
            # IO.puts("ERRORERRORERROR")
            # IO.inspect(changeset)
            |> render("setup.html",
              changeset: changeset,
              organization_id: organization_id,
              token: token
            )

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
