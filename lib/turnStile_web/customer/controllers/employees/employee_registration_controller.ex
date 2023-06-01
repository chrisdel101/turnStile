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
        current_user_permission =
          TurnStile.PermissionsUtils.get_employee_permissions_level(current_employee.role)

        # check level of user being createdd
        registrant_permissions =
          TurnStile.PermissionsUtils.get_employee_permissions_level(Map.get(employee_params, "role"))

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
          case Staff.register_and_preload_employee(employee_params) do
            {:ok, employee} ->
              # IO.inspect("HERE")
              # &1 is a token
              {:ok, _} =
                Staff.deliver_employee_confirmation_instructions(
                  employee,
                  &Routes.employee_confirmation_url(
                    conn,
                    :edit,
                    employee_params["organization_id"],
                    &1
                  )
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
      # create_initial_owner(conn, %{"employee" => employee_params})
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
        current_user_permission =
          TurnStile.PermissionsUtils.get_employee_permissions_level(current_employee.role)

        # check level of user being createdd
        registrant_permissions =
          TurnStile.PermissionsUtils.get_employee_permissions_level(Map.get(employee_params, "role"))

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
          case Staff.register_and_preload_employee(employee_params) do
            {:ok, employee} ->
              # IO.inspect("HERE")
              # &1 is a token
              {:ok, _} =
                Staff.deliver_employee_confirmation_instructions(
                  employee,
                  &Routes.employee_confirmation_url(
                    conn,
                    :edit,
                    employee_params["organization_id"],
                    &1
                  )
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
  def create_initial_owner(conn, organization, %{"employee" => employee_params}) do
    # extract org id
    organization_id = Map.get(organization, "id") || Map.get(organization, :id)
    IO.inspect(organization)
    # check if org already exist - it was just created
    organizations? = TurnStile.Company.check_organization_exists_by_id(organization_id)
    # check if org already exist
    if length(organizations?) === 1 do
      # confirm exists but has no members yet
      members? = OrganizationController.organization_has_members?(organization_id)
      # if member, send error
      if members? do
        error = "Organization setup error. Members already exist."
        {:error, error}
      else
        # add organization_id, role; employee_params = employee_params syntax is required to persist
        employee_params =
          employee_params
          |> Map.put("organization_id", organization_id)
          |> Map.put("roles", [to_string(hd(EmployeeManagerRolesEnum.get_roles()))])

        case Staff.register_and_preload_employee(employee_params) do
          {:ok, employee} ->
            IO.inspect("YYYYYY")
            IO.inspect(employee)
            # require email account confirmation
            if System.get_env("EMPLOYEE_CREATE_CONFIRM_IS_REQUIRED") === "true" do
              zz =
                Staff.deliver_employee_confirmation_instructions(
                  employee,
                  &Routes.employee_confirmation_url(conn, :edit, organization_id, &1)
                )

              IO.inspect('zzzzzzzzz')
              IO.inspect(zz)

              case zz do
                {:ok, _email_body} ->
                  log_in = System.get_env("EMPLOYEE_CREATE_AUTO_LOGIN")
                  {:ok, employee, log_in}
                {:error, error} ->
                  {:error, error}
              end
            else
              vv = Staff.deliver_employee_welcome_email(employee)
              IO.inspect('vvvvvvvvv')
              IO.inspect(vv)

              case vv do
                {:ok, _email_body} ->
                  log_in = System.get_env("EMPLOYEE_CREATE_AUTO_LOGIN")
                  {:ok, employee, log_in}

                {:error, error} ->
                  {:error, error}
              end
            end

          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, changeset}
        end
      end
    else
      error = "Organization not found error. Does not exist"
      {:error, error}
      halt(conn)
    end
  end
end
