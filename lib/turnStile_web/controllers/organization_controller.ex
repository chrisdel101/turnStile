defmodule TurnStileWeb.OrganizationController do
  use TurnStileWeb, :controller

  alias TurnStileWeb.EmployeeRegistrationController
  alias TurnStile.Staff
  alias TurnStile.Company
  alias TurnStile.Company.Organization
  alias TurnStileWeb.EmployeeAuth
  alias TurnStile.Staff.Employee

  # TODO - create permissions to block all end users from seeing this page
  def index(conn, _params) do
    # no end users ever see this page
    organizations = Company.list_organizations()
    render(conn, "index.html", organizations: organizations)
  end

  # init - render form 1
  def new(conn, _params) do
    org_params = get_session(conn, :org_params)
    changeset = Company.change_organization(%Organization{}, org_params || %{})
    IO.inspect(changeset)
    render(conn, "new.html", changeset: changeset)
  end

  # second render - handle submuit form 1; display form 2
  def handle_new(conn, %{"organization" => org_params}) do
    changeset = Company.change_organization(%Organization{}, org_params)
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
        organizations? = Company.check_organization_exists_by_slug(slug)
        org_params = Map.put_new(org_params, "slug", slug)
        # handle duplicate org
        if is_nil(organizations?) || length(organizations?) !== 0 do
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
            conn = assign(conn, :org_form_submitted, true)
            render(conn, "new.html", changeset: employee_changeset)
          else
            employee_changeset = Staff.create_employee(%Employee{})

            # add org params to sessions
            conn = Plug.Conn.put_session(conn, :org_params, org_params)
            # set from partial flag on conn
            conn = assign(conn, :org_form_submitted, true)
            render(conn, "new.html", changeset: employee_changeset)
          end
        end
    end
  end

  # second render - handle same func w/ invalid params for error
  def handle_new(conn, org_params) do
    changeset = Company.change_organization(%Organization{}, org_params)

    conn
    |> put_flash(:error, "A parameter error ocurred. Try again")
    # re-render "new" again w error
    |> render("new.html", changeset: changeset)
  end

  def create(conn, employee_params) do
    # extract params from session
    current_employee = conn.assigns[:current_employee]
    org_params = Map.get(Plug.Conn.get_session(conn), "org_params")
    # add organization
    case Company.create_and_preload_organization(org_params) do
      {:ok, organization} ->
        IO.inspect("ORG HERE")
        IO.inspect(organization)

        if !current_employee do
          x = EmployeeRegistrationController.create_initial_owner(
            conn,
            organization,
            employee_params
          )
          IO.inspect("X HERE")
          IO.inspect(x)
          case x do
            {:error, error} ->
              # delete any organization just saved
              Company.delete_organization(organization)
              IO.inspect("ERROR in create orgnization_controller")
              # conn = assign(conn, :org_form_submitted, true)
              conn
              |> assign(:org_form_submitted, true)
              |> put_flash(:error, "Error in Employee creation. Try again.")
              |> render("new.html", changeset: error)
        # create_initial_owner returns employee & log_in bool
            {:ok, employee, log_in} ->
              # IO.inspect("OK2222")
              # IO.inspect(employee)
              # build instance changeset
              org_changeset = Ecto.Changeset.change(organization)
              # put_assoc
              org_with_emps = Ecto.Changeset.put_assoc(org_changeset, :employees, [employee])
              IO.inspect(org_with_emps)

              case Company.update_organization_changeset(org_with_emps) do
                {:ok, _updated_org} ->
                  IO.inspect("log_in")
                  IO.inspect(log_in)
                  if log_in === "true" do
                    IO.inspect("OK TRUE")
                    params = %{flash: "Organization Successfully created"}
                    EmployeeAuth.log_in_employee_on_create(conn, employee, (Map.get(organization, "id") || Map.get(organization, :id)), Routes.organization_path(conn, :show, organization.id, %{"emptyParams" => true, "paramsKey" => "org_params"}), params)
                  else
                    IO.inspect("OK FALSE")
                    # IO.inspect(updated_org)
                    conn
                    |> put_flash(:info, "An email was sent you your account. Please check your email to confirm your account. ")
                    |> redirect(to: Routes.organization_path(conn, :show, organization.id, %{"emptyParams" => true, "paramsKey" => "org_params"}))
                  end

                {:error, error} ->
                  IO.inspect("ERROR")

                  conn
                  |> assign(:org_form_submitted, true)
                  |> put_flash(:error, "Employee not created. Try again.")

                  render("new.html", changeset: error)
              end
          end
        else
          # IO.inspect("OK2222")
          # IO.inspect(employee)
          # build instance changeset
          org_changeset = Ecto.Changeset.change(organization)
          # put_assoc
          org_with_emps = Ecto.Changeset.put_assoc(org_changeset, :employees, [current_employee])
          IO.inspect(org_with_emps)

          case Company.update_organization_changeset(org_with_emps) do
            {:ok, _updated_org} ->
              # IO.inspect("OK")
              # IO.inspect(updated_org)
              conn
              |> put_flash(:info, "Organization Successfully created.")
              |> redirect(to: Routes.organization_path(conn, :show, organization.id, %{"emptyParams" => true, "paramsKey" => "org_params"}))
            {:error, error} ->
              IO.inspect("ERROR")
              conn
              |> assign(:org_form_submitted, true)
              |> put_flash(:error, "Employee not created. Try again.")
              render("new.html", changeset: error)
          end
        end
      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect("CREATE ERROR")
        IO.inspect(changeset)
        render(conn, "new.html", changeset: changeset)
    end
  end

  # takes ID or name
  def show(conn, %{"id" => id}) do
    organization = Company.get_organization(id)
    if !organization do
      conn
      |> put_flash(:info, "That Organization doesn't exist. Try again.")
      |> redirect(to: Routes.organization_path(conn, :index))
    else
      members? = organization_has_members?(organization.id)
      changeset = Staff.change_employee(%Employee{})

      render(conn, "show.html",
        organization: organization,
        changeset: changeset,
        members?: members?,
        organization_id: organization.id
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

  # check if org has employee members
  def organization_has_members?(id) do
    # members? = Company.check_organization_has_employees(id)
    members? = Staff.list_employee_ids_by_organization(id)

    if !members? or length(members?) === 0 do
      false
    else
      true
    end
  end

  def organization_setup?(conn, _opts) do
    organization_id = conn.params["id"]
    organization? = Company.get_organization(organization_id)

    if !organization? do
      conn
      |> put_flash(:error, "That organization is not setup yet. Setup it to continue. ")
      |> redirect(to: Routes.organization_path(conn, :new))
    end

    conn
  end

  # if org is not setup block request
  # if org is setup, but as no members, allow first time setup reg
  # else require auth
  def req_auth_after_org_setup?(conn, _opts) do
    # if members exist require auth
    organization_id = conn.params["id"]

    if organization_has_members?(organization_id) do
      assign(conn, :current_organization_setup, true)
      # this halts if not authenticated

      # THIS NEED FIXING - [] is just temp fix to make it run
      for_arity_error = []
      EmployeeAuth.require_authenticated_employee(conn, for_arity_error)
    else
      assign(conn, :current_organization_setup, false)
      # if no members, allow first time setup reg
      conn
    end
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
      # redirect to rest using ID - will redriect to name auto
      # Kernal.inpsect makes id a string
      show(conn, %{"param" => Kernel.inspect(organization.id)})
    end
  end

  # plug
  def first_org_form_submit?(conn, bool) do
    assign(conn, :org_form_submitted, bool)
  end

end
