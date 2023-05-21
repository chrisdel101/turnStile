defmodule TurnStileWeb.OrganizationController do
  use TurnStileWeb, :controller

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

  def new(conn, %{"organization" => org_params}) do
    changeset = Company.change_organization(%Organization{}, org_params)
    IO.inspect(changeset)
  #  check if name is filled in
    case Ecto.Changeset.get_change(changeset, :name) do
      # handle empty required params
     value when value in [nil, ""] ->
        # change changset action to insert
        {:error, %Ecto.Changeset{} = changeset} = Ecto.Changeset.apply_action(changeset, :insert)
        # render new again
          render(conn, "new.html", changeset: changeset)
      _ ->
        # Handle the case when the form is submitted with non-empty parameters
        # Process the submitted data and perform any necessary actions
          conn = assign(conn, :org_form_submitted, true)
          render(conn, "new.html", changeset: changeset)
        # case Repo.insert(changeset) do
        #   {:ok, organization} ->
        #     # Redirect to a success page or perform other actions
        #     conn
        #     |> put_flash(:info, "Organization created successfully!")
        #     |> redirect(to: Routes.organization_path(conn, :show, organization))

        #   {:error, changeset} ->
        #     # Handle the case when there are validation errors or other issues
        #     # For example, re-render the form with error messages
        #     render(conn, "new.html", changeset: changeset)
        # end
    end
  end
  # init render
  def new(conn, _params) do
    changeset = Company.change_organization(%Organization{})
    # add flag for org form submission
    conn = assign(conn, :org_form_submitted, false)
    # IO.inspect(param)
    IO.inspect(changeset)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, organization_params) do
    # IO.inspect(organization_params)
    # # extract owner_employee params
    # %{"owner_employee"=>map} = organization_params["organization"]
    # extract org params
    %{"name"=>name} = organization_params["organization"]
    # assign to new variable
    # org_only_params = %{"email"=> email, "name"=>name, "phone"=>phone}
    slug = Slug.slugify(name)
    # org_only_params = Map.put(org_only_params, "slug", slug)
    # IO.inspect(org_only_params)
    organizations? = Company.check_organization_exists_by_slug(slug)
    IO.inspect(organizations?)
    organization_params = Map.put_new(organization_params, "slug", slug)
    # don't allow duplicate org names
    if length(organizations?) !== 0 do
      conn
      |> put_flash(:info, "That Organization already exists. Try another name.")
      |> redirect(to: Routes.organization_path(conn, :new))
    # if doesn't already exist, allow create
    else
      x = Company.create_organization(organization_params)
      # IO.inspect(x)
      case x do
        {:ok, organization} ->
          conn
          |> put_flash(:info, "Organization created successfully.")
          |> redirect(to: Routes.organization_path(conn, :show, organization.id))
        {:error, %Ecto.Changeset{} = changeset} ->
          IO.inspect("CREATE ERROR")
          IO.inspect(changeset)
          render(conn, "new.html", changeset: changeset)
      end
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
      conn
      members? = organization_has_members?(organization.id)
      changeset   = Staff.change_employee(%Employee{})
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

  # reload to display rest with :slug not :id
  defp _reload_with_name_rest(conn, organization_slug) do
    redirect(conn, to: "/organizations/#{organization_slug}")
  end

  # check if org has employee members
  def organization_has_members?(id) do
    # members? = Company.check_organization_has_employees(id)
    members? = Staff.list_employees_by_organization(id)

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
end
