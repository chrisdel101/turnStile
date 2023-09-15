defmodule TurnStileWeb.OrganizationController do
  use TurnStileWeb, :controller

  alias TurnStileWeb.EmployeeRegistrationController
  alias TurnStile.Staff
  alias TurnStile.Company
  alias TurnStile.Company.Organization
  alias TurnStileWeb.EmployeeAuth
  alias TurnStile.Staff.Employee

  plug :track_form_stage

  @moduledoc """
  Controller for managing organizations
  Flow: using multi-step form
  -handled by track_form_stage on each call
  1.init - render form 1 (new_org_form.html)
  2.handle_new - handle submit form 1; display form 2 (new_employee_form.html)
  3.handle_create - handle submit form 2; create org

  """

  def index(conn, _params) do
    # no end users ever see this page
    organizations = Company.list_organizations()
    render(conn, "index.html", organizations: organizations)
  end

  # init - render form 1
  def new(conn, _params) do
    org_params = get_session(conn, :org_params)
    # IO.inspect(org_params)
    changeset = Company.change_organization(%Organization{}, org_params || %{})
    render(conn, "new.html", changeset: changeset)
  end

  # second render - handle submuit form 1; display form 2
  def handle_new(conn, %{"organization" => org_params}) do
    changeset = Company.change_organization(%Organization{}, org_params)
    # IO.inspect( changeset, label: "HERE222")
    # make sure name is not empty
    case Ecto.Changeset.get_change(changeset, :name) do
      # handle empty name
      value when value in [nil, ""] ->
        # change changset action to insert
        {:error, %Ecto.Changeset{} = changeset} = Ecto.Changeset.apply_action(changeset, :insert)
        # re-render "new" again
        render(conn, "new.html", changeset: changeset)

      # when valid name field
      _ ->
        # extract name
        %{"name" => name} = org_params
        # make slug
        slug = Slug.slugify(name)
        # check DB for org
        existing_orgs = Company.check_organization_exists_by_slug(slug)
        org_params = Map.put_new(org_params, "slug", slug)
        # handle duplicate org
        if length(existing_orgs) > 0 do
          conn
          |> put_flash(:info, "That Organization already exists. Try another name.")
          |> render("new.html", changeset: changeset)
        else
          current_employee = conn.assigns[:current_employee]

          if current_employee do
            employee_changeset = Ecto.Changeset.change(current_employee)
            # add org params to sessions
            conn = Plug.Conn.put_session(conn, :org_params, org_params)
            # set from partial flag on conn
            # conn = assign(conn, :org_form_submitted, true)
            conn = track_form_stage(conn, nil, true)

            render(conn, "new.html", changeset: employee_changeset)
          else
            employee_changeset = Staff.create_employee(%Employee{})

            # add org params to sessions
            conn = Plug.Conn.put_session(conn, :org_params, org_params)
            # set from partial flag on conn
            # conn = assign(conn, :org_form_submitted, true)
            conn = track_form_stage(conn, nil, true)
            render(conn, "new.html", changeset: employee_changeset)
          end
        end
    end
  end

  # second render - handle same func w/ invalid params for error
  def handle_new(conn, org_params) do
    changeset = Company.change_organization(%Organization{}, org_params)

    conn
    |> put_flash(:error, "A parameter error ocurred. Cancel and retry.")
    # re-render "new" again w error
    |> render("new.html", changeset: changeset)
  end

  def create(conn, employee_params) do
    IO.inspect(employee_params, label: "employee_params")
    # extract params from session
    current_employee = conn.assigns[:current_employee]
    org_params = Map.get(get_session(conn), "org_params")

    # add organization
    case Company.insert_and_preload_organization(org_params) do
      {:ok, organization} ->
        IO.inspect(organization, label: "insert_and_preload_organization")
        # creating initial employee
        if !current_employee do
          role =
            TurnStile.Roles.build_role(%{
              name: EmployeeRolesMap.get_permission_role("OWNER"),
              value: to_string(EmployeeRolesMap.get_permission_role_value("OWNER"))
            })
          case EmployeeRegistrationController.create_initial_owner(
            conn,
            organization,
            employee_params
          ) do
            {:error, error} ->
              # delete any organization just saved
              Company.delete_organization(organization)
              IO.inspect(error, label: "ERROR in create orgnization_controller")
              # conn = assign(conn, :org_form_submitted, true)
              conn = track_form_stage(conn, nil, true)
              conn
              |> assign(:org_form_submitted, true)
              |> put_flash(:error, "Error in Employee creation: Try again.")
              |> render("new.html", changeset: error)

            # create_initial_owner returns employee, log_in? bool
            {:ok, employee, log_in?} ->
              case TurnStile.Company.update_employee_assoc(organization, employee) do
                {:ok, updated_org} ->
                  IO.inspect(updated_org, label: "updated_org123")
                  # add has_many role assocations
                  role = TurnStile.Roles.assocaiate_role_with_employee(role, employee)
                  role = TurnStile.Roles.assocaiate_role_with_organization(role, updated_org)

                  IO.inspect(employee, label: "employee")
                  # IO.inspect(updated_org, label: "updated_org")
                  IO.inspect(role, label: "role")

                  case TurnStile.Roles.insert_role(employee.id, updated_org.id, role) do
                    {:error, error} ->
                      # delete any prev created employees in workflow
                      Staff.delete_employee(employee)
                      {:error, error}

                    {:ok, role} ->
                      IO.inspect(role, label: "ROLE2")
                      IO.inspect(log_in?)

                      if log_in? === "true" do
                        IO.inspect("OK TRUE")
                        params = %{flash: "Organization Successfully created"}

                        EmployeeAuth.log_in_employee_on_create(
                          conn,
                          employee,
                          Map.get(organization, "id") || Map.get(organization, :id),
                          Routes.organization_path(conn, :show, organization.id, %{
                            "emptyParams" => true,
                            "paramsKey" => "org_params"
                          }),
                          params
                        )
                      else
                        # IO.inspect(updated_org)
                        conn
                        |> put_flash(
                          :info,
                          "An email was sent you your account. Please check your email to confirm your account. "
                        )
                        |> redirect(
                          to:
                            Routes.organization_path(conn, :show, organization.id, %{
                              "emptyParams" => true,
                              "paramsKey" => "org_params"
                            })
                        )
                      end
                  end

                {:error, error} ->
                  IO.inspect(error, label: "ERROR")
                  # delete any emplpyees created during failed workflow
                    Staff.delete_employee(employee)

                  conn
                  |> assign(:org_form_submitted, true)
                  |> put_flash(:error, "Error in assocaitions. Employee not created. Try again.")
                  |> render("new.html", changeset: error)
              end

            #  default case; if runtime or unknown error, etc
            _ ->
              # delete any organization just saved
              Company.delete_organization(organization)

              error_msg = "ERROR in create orgnization_controller default case"
              IO.inspect(error_msg)
              # conn = assign(conn, :org_form_submitted, true)
              conn
              |> track_form_stage(nil, true)
              |> put_flash(:error, error_msg)
              |> render("new.html",
                changeset: Employee.registration_changeset(%Staff.Employee{}, %{})
              )
          end

          # adding existing employee to new org
          # TODO: feature UNTESTED - seems to work
        else
          # existing employee will be owner on new org
          role =
            TurnStile.Roles.build_role(%{
              name: EmployeeRolesMap.get_permission_role("OWNER"),
              value: to_string(EmployeeRolesMap.get_permission_role_value("OWNER"))
            })

          case TurnStile.Company.update_employee_assoc(organization, current_employee) do
            {:ok, updated_org} ->
              IO.inspect(updated_org, label: "updated_org567")
              # add has_many role assocations
              role = TurnStile.Roles.assocaiate_role_with_employee(role, current_employee)
              role = TurnStile.Roles.assocaiate_role_with_organization(role, updated_org)
              IO.inspect("log_in?")

              case TurnStile.Roles.insert_role(current_employee.id, updated_org.id, role) do
                {:error, error} ->
                  {:error, error}

                {:ok, role} ->
                  IO.inspect(role, label: "ROLE")
                  # IO.inspect("OK")
                  # IO.inspect(updated_org)
                  conn
                  |> put_flash(:info, "Organization Successfully created.")
                  |> redirect(
                    to:
                      Routes.organization_path(conn, :show, organization.id, %{
                        "emptyParams" => true,
                        "paramsKey" => "org_params"
                      })
                  )
              end

            {:error, error} ->
              IO.inspect("ERROR")

              conn
              |> track_form_stage(nil, true)
              |> put_flash(:error, "Employee not created. Try again.")
              |> render("new.html", changeset: error)
          end
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect("CREATE ERROR")
        IO.inspect(changeset)
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    organization = Company.get_organization(id)

    if !organization do
      conn
      |> put_flash(:info, "That Organization doesn't exist. Try again.")
      |> redirect(to: Routes.organization_path(conn, :index))
    else
      members? = Company.organization_has_members?(organization.id)
      # TODO: make a special login changeset
      changeset = Staff.change_employee(%Employee{})

      render(conn, "show.html",
        organization: organization,
        changeset: changeset,
        members?: members?,
        organization_id: organization.id,
        error_message: nil
      )
    end
  end

  def edit(conn, %{"id" => id}) do
    organization = Company.get_organization(id)
    changeset = Company.change_organization(organization)
    render(conn, "edit.html", organization: organization, changeset: changeset)
  end

  def update(conn, %{"id" => id, "organization" => organization_params}) do
    organization = Company.get_organization(id)

    case Company.update_organization(organization, organization_params) do
      {:ok, organization} ->
        conn
        |> put_flash(:info, "Organization updated successfully.")
        |> redirect(to: Routes.organization_path(conn, :show, organization))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", organization: organization, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    organization = Company.get_organization(id)
    {:ok, _organization} = Company.delete_organization(organization)

    conn
    |> put_flash(:info, "Organization deleted successfully.")
    |> redirect(to: Routes.organization_path(conn, :index))
  end

  # display search bar for organizations
  def search_get(conn, _params) do
    changeset = Company.change_organization(%Organization{})
    organizations = Company.list_organizations()
    render(conn, "search.html", changeset: changeset, organizations: organizations)
  end

  # execute search bar for organizations, direct to show page or show error
  def search_post(conn, params) do
    # slugigy param
    slug = Slug.slugify(params["organization"]["name"] || "")
    # check if org name exists
    organization = Company.get_organization_by_name(slug)

    if !organization do
      conn
      |> put_flash(:error, "No organization by that name.")
      |> redirect(to: Routes.organization_path(conn, :search_get))
    else
      redirect(conn, to: Routes.organization_path(conn, :show, organization.id))
    end
  end

  # plug
  # sets flag to false unless manulally set to true
  defp track_form_stage(conn, _opts, bool \\ false) do
    # IO.inspect(bool, label: "bool")
      conn
      |> assign(:org_form_submitted, bool)
  end
end
