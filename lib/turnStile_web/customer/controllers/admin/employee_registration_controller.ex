defmodule TurnStileWeb.EmployeeRegistrationController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStile.Staff.Employee
  alias TurnStileWeb.EmployeeAuth
  alias TurnStileWeb.OrganizationController

  def new(conn, _params) do
    changeset = Staff.change_employee_registration(%Employee{})
    organization_id = conn.path_params["id"]
    IO.puts("HERE")
    IO.inspect(conn)
    render(conn, "new.html", changeset: changeset, organization_id: organization_id)
  end

  def create(conn, %{"employee" => employee_params}) do
    current_employee = conn.assigns[:current_employee]
    # setup organization process
    if !current_employee do
      setup_initial_owner(conn, %{"employee" => employee_params})
    else
      organization_id = conn.path_params["id"]
      if !organization_id do
        conn
        |> put_flash(:error, "An Organization ID error ocurred. Make sure it exists.")
        |> redirect(to: Routes.organization_path(conn, :index))
      end
      organizations? = TurnStile.Company.check_organization_exists_by_id(organization_id)
      if length(organizations?) != 1 do
        conn
        |> put_flash(:info, "An Organization error ocurred. Make sure it exists.")
        |> redirect(to: Routes.organization_path(conn, :new))
      else
        # check employee doing the creating permissions
        current_user_permission = TurnStile.Utils.get_permissions_level_int(current_employee.role)
        # check level of user being createdd
        registrant_permissions =
          TurnStile.Utils.get_permissions_level_int(Map.get(employee_params, "role"))

        # make sure adequate perms - only register permissions level >= self
        if registrant_permissions >
        current_user_permission do

          changeset = Staff.change_employee_registration(%Employee{}, employee_params)

          conn
          # if employee does not have permissions - flash and re-render
          |> put_flash(:error, "Invalid Permssions to create that user")
          |> render("new.html", changeset: changeset, organization_id: organization_id)
        else
          case Staff.register_employee(employee_params) do
            {:ok, employee} ->
              {:ok, _} =
                Staff.deliver_employee_confirmation_instructions(
                  employee,
                  &Routes.employee_confirmation_url(conn, :edit, &1)
                )

              conn
              |> put_flash(:info, "Employee created successfully.")
              |> EmployeeAuth.log_in_employee(employee)

            {:error, %Ecto.Changeset{} = changeset} ->
              render(conn, "new.html", changeset: changeset, organization_id: organization_id)
          end
        end
      # end
      end
      # check employee doing the creating permissions
      current_user_permission = TurnStile.Utils.get_permissions_level_int(current_employee.role)
      # check level of user being createdd
      registrant_permissions =
        TurnStile.Utils.get_permissions_level_int(Map.get(employee_params, "role"))

      # make sure adequate perms - only register permissions level >= self
      if registrant_permissions >
      current_user_permission do

        changeset = Staff.change_employee_registration(%Employee{}, employee_params)

        conn
        # if employee does not have permissions - flash and re-render
        |> put_flash(:error, "Invalid Permssions to create that user")
        |> render("new.html", changeset: changeset)
      end
  end

    case Staff.register_employee(employee_params) do
      {:ok, employee} ->
        {:ok, _} =
          Staff.deliver_employee_confirmation_instructions(
            employee,
            &Routes.employee_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "Employee created successfully.")
        |> EmployeeAuth.log_in_employee(employee)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  # create first user as owner
  defp setup_initial_owner(conn, %{"employee" => employee_params}) do
    # confirm org exists
    organization_id = conn.path_params["id"]
    organizations? = TurnStile.Company.check_organization_exists_by_id(organization_id)
    # check if org already exis
    if length(organizations?) === 1 do
      # confirm org has no members/ so is not setup
      members? = OrganizationController.organization_has_members?(organization_id)
      # if member, send error
      if members? do
        conn
        |> put_flash(:error, "Organization already setup. Login is required")
        |> redirect(to: Routes.page_path(conn, :index))
       # if no members, allow setup
      else
        # add organization_id to params
        employee_params = Map.put(employee_params, "organization_id", organization_id)
        # create owner
        case Staff.register_employee(employee_params) do
          {:ok, employee} ->
            {:ok, _} =
              Staff.deliver_employee_confirmation_instructions(
                employee,
                &Routes.employee_confirmation_url(conn, :edit, organization_id, &1)
              )

            conn
            |> put_flash(:info, "Setup Owner created successfully.")
            |> EmployeeAuth.log_in_employee(employee)

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "new.html", changeset: changeset, organization_id: organization_id)
        end
      end
    else
      conn
      |> put_flash(:error, "Organization does not exist")
      |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end