defmodule TurnStileWeb.EmployeeRegistrationController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStile.Staff.Employee
  alias TurnStile.Company

  def new(conn, _params) do
    changeset = Staff.change_employee_registration(%Employee{})
    organization_id = conn.path_params["id"]
    render(conn, "new.html", changeset: changeset, organization_id: organization_id)
  end

  def create(conn, %{"employee" => employee_params}) do
    IO.inspect(conn)
    current_employee = conn.assigns[:current_employee]
    # if no logged in employee
    if !current_employee do
      conn
      |> put_flash(:error, "You must be logged in to your Organization.")
      |> redirect(to: Routes.organization_path(conn, :search_get))
    else
      organization_id = conn.path_params["id"]
      # if no org_id found flash error
      if !organization_id do
        conn
        |> put_flash(:error, "An Organization ID error occurred. Make sure it exists.")
        |> redirect(to: Routes.organization_path(conn, :index))
      end

      # check org exists
      organization =
        Company.get_organization(organization_id)
        |> TurnStile.Repo.preload(:employees)

      # IO.inspect("ZZZZZ")
      # IO.inspect(organization)
      # if no org by org_id flash error
      if !organization do
        conn
        |> put_flash(:info, "An Organization error occurred. Make sure it exists.")
        |> redirect(to: Routes.organization_path(conn, :new))
      else
        # make sure there are some members
        members? = Company.organization_has_members?(organization_id)

        # if no members, send error
        if !members? do
          error =
            "No members already exist. The first member should be created with the organization."

          IO.puts("Error: registration create error: organization exists w/o founding member.")
          {:error, error}
        else
          IO.inspect("ZZZZZ employee_params")
          IO.inspect(employee_params)

          x =
            TurnStileWeb.EmployeeAuth.has_sufficient_register_permissions?(conn, employee_params)

          IO.inspect("HERE")
          IO.inspect(x)
          # Invalid permission - reload page
          error_changeset = Staff.change_employee_registration(%Employee{}, employee_params)

          if !x do
            conn
            # if employee does not have permissions - flash and re-render
            |> put_flash(:error, "Invalid Permissions to create that user level")
            |> render("new.html", changeset: error_changeset, organization_id: organization_id)
          else
            case Staff.register_and_preload_employee(employee_params, organization) do
              {:ok, employee} ->
                IO.inspect("EEEEE")
                IO.inspect(employee)

                case Company.handle_new_employee_association(organization, employee) do
                  {:ok, _updated_org} ->
                    IO.inspect("YYYYYY")
                    IO.inspect(employee)
                    # require email account confirmation
                    cond do
                      System.get_env("EMPLOYEE_CREATE_SETUP_IS_REQUIRED") === "false" ->
                        # just send welcomemail; no setup required
                        case Staff.deliver_init_employee_welcome_email(employee) do
                          {:ok, _email_body} ->
                            conn
                            |> put_flash(:info, "Employee created successfully.")
                            |> redirect(
                              to: Routes.employee_registration_path(conn, :new, organization_id)
                            )
                          {:error, error} ->
                            {:error, error}
                        end

                      # default case - send setup email
                      true ->
                        zz =
                          Staff.deliver_employee_setup_email(
                            employee,
                            &Routes.employee_confirmation_url(conn, :setup, organization_id, &1)
                          )
                          IO.inspect(zz)
                          case zz do
                            {:ok, email_body} ->
                              IO.inspect("ZZZZZ")
                              IO.inspect(email_body)

                            conn
                            |> put_flash(
                              :info,
                              "Employee created successfully. A confirmation email was sent to the new employee."
                            )
                            |> redirect(
                              to: Routes.employee_registration_path(conn, :new, organization_id)
                            )

                          {:error, error} ->
                            {:error, error}
                        end
                    end

                  {:error, %Ecto.Changeset{} = changeset} ->
                    render(conn, "new.html",
                      changeset: changeset,
                      organization_id: organization_id
                    )
                end

              {:error, %Ecto.Changeset{} = changeset} ->
                render(conn, "new.html", changeset: changeset, organization_id: organization_id)
            end
          end
        end
      end
    end
  end

  @doc """
  create_initial_owner - creates the first employee of an organization
  - is automatically assigned the owner role
  """
  def create_initial_owner(conn, organization, %{"employee" => employee_params}) do
    # extract org id
    organization_id = Map.get(organization, "id") || Map.get(organization, :id)
    IO.inspect(organization)
    # check if org already exist - it was just created
    organizations = Company.get_organization(organization_id)
    # check if org already exist
    if organizations do
      # confirm exists but has no members yet
      members? = Company.organization_has_members?(organization_id)
      # if member, send error
      if members? do
        error = "Organization setup error. Members already exist."
        {:error, error}
      else
        # add organization_id, role; employee_params = employee_params syntax is required to persist
        employee_params =
          employee_params
          |> Map.put("organization_id", organization_id)
          |> Map.put("role_on_current_organization", RoleValuesMap.get_permission_role("owner"))

        # IO.inspect("ZZZZZ")
        # IO.inspect(employee_params)

        case Staff.register_and_preload_employee(employee_params, organization) do
          {:ok, employee} ->
            IO.inspect("YYYYYY")
            IO.inspect(employee)
            # require email account confirmation
            if System.get_env("REQUIRE_INIT_EMPLOYEE_CONFIRMATION") === "true" do
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
              vv = Staff.deliver_init_employee_welcome_email(employee)
              IO.inspect('vvvvvvvvv')
              IO.inspect(vv)

              case vv do
                {:ok, _email_body} ->
                  log_in = System.get_env("EMPLOYEE_CREATE_INIT_AUTO_LOGIN")
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
