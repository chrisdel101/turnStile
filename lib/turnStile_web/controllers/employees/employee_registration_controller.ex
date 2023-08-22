defmodule TurnStileWeb.EmployeeRegistrationController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStile.Staff.Employee
  alias TurnStile.Company

  def new(conn, _params) do
    organization_id = conn.path_params["id"]

    changeset =
      Staff.change_employee_registration(%Employee{}, %{}, organization_id: organization_id)

    render(conn, "new.html", changeset: changeset, organization_id: organization_id)
  end

  # - create all other employees via register; o
  # organizations/:id/employees/register
  def create(conn, %{"employee" => employee_params}) do
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

          x = TurnStileWeb.EmployeeAuth.has_employee_register_permissions?(conn, employee_params)

          IO.inspect("HERE")
          IO.inspect(x)
          # Invalid permission - reload page
          error_changeset =
            Staff.change_employee_registration(%Employee{}, employee_params,
              organization_id: organization_id
            )

          if !x do
            conn
            # if employee does not have permissions - flash and re-render
            |> put_flash(:error, "Invalid Permissions to create that user level")
            |> render("new.html", changeset: error_changeset, organization_id: organization_id)
          else
            case Staff.insert_register_employee(employee_params, organization_id: organization_id) do
              {:ok, employee} ->
                IO.inspect("EEEEE")
                IO.inspect(employee)

                case Company.update_employee_assoc(organization, employee) do
                  {:error, error} ->
                    {:error, error}

                  {:ok, updated_org} ->
                    # IO.inspect("updated_org")
                    # IO.inspect(updated_org)
                    # add employee/org role
                    role =
                      TurnStile.Roles.build_role(%{
                        name:
                          EmployeeRolesMap.get_permission_role(
                            String.upcase(
                              employee_params["role_on_current_organization"] ||
                                employee_params[:role_on_current_organization] || ""
                            )
                          ),
                        value:
                          to_string(
                            EmployeeRolesMap.get_permission_role_value(
                              String.upcase(
                                employee_params["role_on_current_organization"] ||
                                  employee_params[:role_on_current_organization] || ""
                              )
                            )
                          )
                      })

                    role_w_emp = TurnStile.Roles.assocaiate_role_with_employee(role, employee)
                    role_w_org = TurnStile.Roles.assocaiate_role_with_organization(role_w_emp, updated_org)

                    case TurnStile.Roles.insert_role(employee.id, updated_org.id, role_w_org) do
                      {:error, error} ->
                        IO.puts("Error: registration create error: role creation failed. #{error}")
                        # delete employee prev inserted
                        Staff.delete_employee(employee)
                        conn
                          |> put_flash(:error, "System error occured. Employee creation failed.")
                          |> redirect(
                            to:
                              Routes.employee_registration_path(conn, :new, organization_id)
                          )

                      {:ok, _role} ->
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
                                  to:
                                    Routes.employee_registration_path(conn, :new, organization_id)
                                )

                              {:error, error} ->
                                {:error, error}
                            end

                          # default case - send setup email
                          true ->
                            zz =
                              Staff.deliver_employee_setup_email(
                                employee,
                                &Routes.employee_confirmation_url(
                                  conn,
                                  :setup,
                                  organization_id,
                                  &1
                                )
                              )

                            # IO.inspect(zz)
                            case zz do
                              {:ok, email_body} ->
                                if Mix.env() == :test do
                                  IO.inspect(email_body)
                                end

                                conn
                                |> put_flash(
                                  :info,
                                  "Employee created successfully. A confirmation email was sent to the new employee."
                                )
                                |> redirect(
                                  to:
                                    Routes.employee_registration_path(conn, :new, organization_id)
                                )

                              {:error, error} ->
                                IO.inspect("error")
                                IO.inspect(error)
                                {:error, error}
                            end
                        end
                    end
                end

              {:error, %Ecto.Changeset{} = changeset} ->
                render(conn, "new.html",
                  changeset: changeset,
                  organization_id: organization_id
                )
              end
            end
          end
      end
    end
  end

  @doc """
  create_initial_owner - creates the first employee of an organization
  - is automatically assigned the owner role
  - called in Organziation controller create
  """
  def create_initial_owner(conn, organization, %{"employee" => employee_params}) do
    # extract org id

    organization_id = Map.get(organization, "id") || Map.get(organization, :id)
    # check if org already exist - it was just created
    organizations = Company.get_organization(organization_id)
    # check if org already exist
    if organizations do
      # double-confirm exists, but has no members yet
      members? = Company.organization_has_members?(organization_id)
      # if member, send error; cannot have members already
      if members? do
        error = "Organization setup error. Members already exist."
        {:error, error}
      else
        case Staff.insert_register_employee(employee_params, organization: organization) do
          {:ok, employee} ->
            IO.inspect("YYYYYY")
            IO.inspect(employee)
            # require email account confirmation
            if System.get_env("REQUIRE_INIT_EMPLOYEE_CONFIRMATION") === "true" do
              zz =
                Staff.deliver_employee_confirmation_instructions(
                  employee,
                  &Routes.employee_confirmation_url(conn, :setup, organization_id, &1)
                )

              IO.inspect('zzzzzzzzz')
              IO.inspect(zz)

              case zz do
                {:ok, _email_body} ->
                  log_in? = System.get_env("EMPLOYEE_CREATE_AUTO_LOGIN")
                  {:ok, employee, log_in?}

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
