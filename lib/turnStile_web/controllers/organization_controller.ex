defmodule TurnStileWeb.OrganizationController do
  use TurnStileWeb, :controller

  alias TurnStile.Company
  alias TurnStile.Company.Organization
  alias TurnStileWeb.AdminAuth

  def index(conn, _params) do
    # only app in-company app developers can see this
    organizations = Company.list_organizations()
    render(conn, "index.html", organizations: organizations)
  end

  def new(conn, _params) do
    changeset = Company.change_organization(%Organization{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"organization" => organization_params}) do
    slug = Slug.slugify(organization_params["name"])
    organization_params = Map.put(organization_params, "slug", slug)
    organizations? = Company.check_organization_exists_by_slug(slug)
    # don't allow duplicate org names
    if length(organizations?) !== 0 do
      conn
      |> put_flash(:info, "That Organization already exists. Try another name.")
      |> redirect(to: Routes.organization_path(conn, :new))
    # if doesn't already exist, allow create
    else
      case Company.create_organization(organization_params) do
        {:ok, organization} ->
          conn
          |> put_flash(:info, "Organization created successfully.")
          |> redirect(to: Routes.organization_path(conn, :show, organization))
        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "new.html", changeset: changeset)
      end
    end
  end

  # takes ID or name
  def show(conn, %{"param" => param}) do
    IO.inspect("SHOW")
    IO.inspect(param)
    # confirms org is setup
    changeset = Company.change_organization(%Organization{})
    # param is ID in URL
    if TurnStile.Utils.is_digit(param) do
      organization = Company.get_organization(param)
      #  if org doesn't exist
      if !organization do
        conn
        |> put_flash(:info, "That Organization doesn't exist. Create it to continue.")
        |> redirect(to: Routes.organization_path(conn, :new))
      end

      reload_with_name_rest(conn, organization.slug, changeset: changeset)
    else
      organization = Company.get_organization_by_name(param)
      IO.inspect("XXXX")
      IO.inspect(organization)
      # if org doesn't exist
      if !organization do
        conn
        |> put_flash(:info, "That Organization doesn't exist. Create it to continue.")
        |> redirect(to: Routes.organization_path(conn, :new))
      end

      members? = organization_has_members?(organization.id)

      render(conn, "show.html",
        organization: organization,
        changeset: changeset,
        members?: members?
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
  defp reload_with_name_rest(conn, organization_slug, changeset: changeset) do
    redirect(conn, to: "/organizations/#{organization_slug}", changeset: changeset)
  end

  # check if org has admin members
  def organization_has_members?(id) do
    members? = Company.check_organization_has_admins(id)

    if !members? or length(members?) === 0 do
      false
    else
      true
    end
  end

  def organization_setup?(conn, _opts) do
    organization_id = conn.params["id"]
    organization? = Company.get_organization(organization_id)
    IO.inspect("EREWER")
    IO.inspect(organization?)

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

      # THIS NEED FIXING
      for_arity_error = []
      AdminAuth.require_authenticated_admin(conn, for_arity_error)
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
