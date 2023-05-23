defmodule TurnStileWeb.EmployeeRegistrationController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStile.Staff.Employee
  alias TurnStileWeb.EmployeeAuth
  alias TurnStileWeb.OrganizationController

  def new(conn, _params) do
    changeset = Staff.change_employee_registration(%Employee{})
    organization_id = conn.path_params["id"]
    render(conn, "new.html", changeset: changeset, organization_id: organization_id)
  end

  def create(conn, %{"employee" => employee_params}) do
    current_employee = conn.assigns[:current_employee]
    # if no logged in employee
    if !current_employee do
      conn
        |> put_flash(:error, "You must be log in to your Organization.")
        |> redirect(to: Routes.organization_path(conn, :search_get))
    else
      organization_id = conn.path_params["id"]
      # if no org_id found flash error
      if !organization_id do
        conn
        |> put_flash(:error, "An Organization ID error ocurred. Make sure it exists.")
        |> redirect(to: Routes.organization_path(conn, :index))
      end

      # check org exist by org_id
      organizations? = TurnStile.Company.check_organization_exists_by_id(organization_id)
      # if no org by org_id flash error
      if length(organizations?) != 1 do
        conn
        |> put_flash(:info, "An Organization error ocurred. Make sure it exists.")
        |> redirect(to: Routes.organization_path(conn, :new))
      else
        # check employee doing the creating permissions
        current_user_permission = TurnStile.Utils.get_employee_permissions_level(current_employee.role)
        # check level of user being createdd
        registrant_permissions =
          TurnStile.Utils.get_employee_permissions_level(Map.get(employee_params, "role"))

        # check perms - only register permissions level >= self -> lower numb is higher perms
        if registrant_permissions >
             current_user_permission do
          # Invalid persmission - reload page
          changeset = Staff.change_employee_registration(%Employee{}, employee_params)

          conn
          # if employee does not have permissions - flash and re-render
          |> put_flash(:error, "Invalid Permssions to create that user")
          |> render("new.html", changeset: changeset, organization_id: organization_id)
        else
          # add organization_id to employee_params
          employee_params = Map.put(employee_params, "organization_id", organization_id)
          # if permissions okay
          case Staff.register_employee(employee_params) do
            {:ok, employee} ->
              # IO.inspect("HERE")
              {:ok, _} =
                # &1 is a token
                Staff.deliver_employee_confirmation_instructions(
                  employee,
                  &Routes.employee_confirmation_url(conn, :edit, employee_params["organization_id"], &1)
                )
              conn
              |> put_flash(:info, "Employee created successfully.")
              |> EmployeeAuth.log_in_employee(employee)

            {:error, %Ecto.Changeset{} = changeset} ->
              render(conn, "new.html", changeset: changeset, organization_id: organization_id)
          end
        end
      end
    end
  end

  def create_owner_employee(conn, %{"owner_employee" => employee_params}) do
    current_employee = conn.assigns[:current_employee]
    # setup organization process
    if !current_employee do
      # setup_initial_owner(conn, %{"employee" => employee_params})
    else
      organization_id = conn.path_params["id"]
      # if n  o org_id found flash error
      if !organization_id do
        conn
        |> put_flash(:error, "An Organization ID error ocurred. Make sure it exists.")
        |> redirect(to: Routes.organization_path(conn, :index))
      end

      # check org exist by org_id
      organizations? = TurnStile.Company.check_organization_exists_by_id(organization_id)
      # if no org by org_id flash error
      if length(organizations?) != 1 do
        conn
        |> put_flash(:info, "An Organization error ocurred. Make sure it exists.")
        |> redirect(to: Routes.organization_path(conn, :new))
      else
        # check employee doing the creating permissions
        current_user_permission = TurnStile.Utils.get_employee_permissions_level(current_employee.role)
        # check level of user being createdd
        registrant_permissions =
          TurnStile.Utils.get_employee_permissions_level(Map.get(employee_params, "role"))

        # check perms - only register permissions level >= self -> lower numb is higher perms
        if registrant_permissions >
             current_user_permission do
          # Invalid persmission - reload page
          changeset = Staff.change_employee_registration(%Employee{}, employee_params)

          conn
          # if employee does not have permissions - flash and re-render
          |> put_flash(:error, "Invalid Permssions to create that user")
          |> render("new.html", changeset: changeset, organization_id: organization_id)
        else
          # add organization_id to employee_params
          employee_params = Map.put(employee_params, "organization_id", organization_id)
          # if permissions okay
          case Staff.register_employee(employee_params) do
            {:ok, employee} ->
              # IO.inspect("HERE")
              {:ok, _} =
                # &1 is a token
                Staff.deliver_employee_confirmation_instructions(
                  employee,
                  &Routes.employee_confirmation_url(conn, :edit, employee_params["organization_id"], &1)
                )
              conn
              |> put_flash(:info, "Employee created successfully.")
              |> EmployeeAuth.log_in_employee(employee)

            {:error, %Ecto.Changeset{} = changeset} ->
              render(conn, "new.html", changeset: changeset, organization_id: organization_id)
          end
        end
      end
    end
  end

  # create first user as owner
  def setup_initial_owner(conn, organization, %{"employee" => employee_params}) do
    # IO.inspect("employee_params INNER")
    # IO.inspect(employee_params)

      # extract org id
    organization_id = Map.get(organization, "id") || Map.get(organization, :id)
    IO.inspect(organization)
    # check if org already exist
    organizations? = TurnStile.Company.check_organization_exists_by_id(organization_id)

    IO.inspect("organizations?")
    IO.inspect(organizations?)
    # check if org already exist
    if length(organizations?) === 1 do
      # confirm org has no members yet
      members? = OrganizationController.organization_has_members?(organization_id)
      # if member, send error
      IO.inspect("members??")
      IO.inspect(members?)
      if members? do
        error  = "Organization already setup. Login is required"
        {:error, error}
        # if no members, allow setup
      else
        # add organization_id, role
        employee_params = employee_params
        |> Map.put("organization_id", organization_id)
        |> Map.put("role", to_string(hd EmployeeManagerRolesEnum.get_roles()))
        case Staff.register_employee(employee_params) do
          {:ok, employee} ->
            IO.inspect("YYYYYY")
            IO.inspect(employee)
              case Staff.deliver_employee_confirmation_instructions(
                employee,
                &Routes.employee_confirmation_url(conn, :edit, employee.id, &1)) do
                {:ok, _} ->
                  success = "Account created. Please check your email for confirmation link."
                  {:ok, employee, success}
                {:error, error} ->
                  {:error, error}
              end
          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, changeset}
        end
      end
    else
      error  = "Organization not found error. Does not exist"
      {:error, error}
      halt(conn)
    end
  end
end
