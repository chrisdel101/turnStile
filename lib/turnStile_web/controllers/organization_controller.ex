defmodule TurnStileWeb.OrganizationController do
  use TurnStileWeb, :controller

  alias TurnStile.Company
  alias TurnStile.Company.Organization

  def index(conn, _params) do
    # only app in-company app developers can see this
    organizations = Company.list_organizations()
    render(conn, "index.html", organizations: organizations)
  end
  # display search bar for organizations
  def display_search(conn, _params) do
    changeset = Company.change_organization(%Organization{})
    organizations = Company.list_organizations()
    render(conn, "search.html", changeset: changeset, organizations: organizations)
  end
  # execute search bar for organizations, direct to show page or show error
  def execute_search(conn, params) do
    # slugigy param
    slug = Slug.slugify(params["organization"]["name"] || "")
    # check if org name exists
    organization = Company.get_organization_by_name!(slug)
    if !organization do
      conn
      |> put_flash(:error, "No organization by that name.")
      |> redirect(to: Routes.organization_path(conn, :display_search))
    else
      # redirect to rest using ID - will redriect to name auto
      # Kernal.inpsect makes id a string
      show(conn, %{"param"=> Kernel.inspect(organization.id)})
    end
  end

  def new(conn, _params) do
    changeset = Company.change_organization(%Organization{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"organization" => organization_params}) do
    slug = Slug.slugify(organization_params["name"])
    organization_params = Map.put(organization_params, "slug", slug)
    # IO.inspect(organization_params)
    case Company.create_organization(organization_params) do
      {:ok, organization} ->
        conn
        |> put_flash(:info, "Organization created successfully.")
        |> redirect(to: Routes.organization_path(conn, :show, organization))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
  # takes ID or name
  def show(conn, %{"param" => param}) do
    IO.inspect("SHOW")
    IO.inspect(param)

    members? = is_organiztion_setup()

    changeset = Company.change_organization(%Organization{})
    # param is ID in URL
    if TurnStile.Utils.is_digit(param) do
      organization = Company.get_organization!(param)
      reload_with_name_rest(conn, organization.slug, changeset: changeset)
    else
      organization = Company.get_organization_by_name!(param)
      # reload_with_name_rest(conn, organization.slug, changeset: changeset)
      render(conn, "show.html", organization: organization, changeset: changeset, members?: members?)
    end
  end

  def edit(conn, %{"id" => id}) do
    organization = Company.get_organization!(id)
    changeset = Company.change_organization(organization)
    render(conn, "edit.html", organization: organization, changeset: changeset)
  end

  def update(conn, %{"id" => id, "organization" => organization_params}) do
    organization = Company.get_organization!(id)

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
    organization = Company.get_organization!(id)
    {:ok, _organization} = Company.delete_organization(organization)

    conn
    |> put_flash(:info, "Organization deleted successfully.")
    |> redirect(to: Routes.organization_path(conn, :index))
  end

  # reload to display rest with :slug not :id
  defp reload_with_name_rest(conn, organization_slug, changeset: changeset) do
    redirect(conn, to: "/organizations/#{organization_slug}", changeset: changeset)
  end
  # check if org has members
  defp is_organiztion_setup do
    members? = Company.check_organization()
    if !members? or length(members?) === 0 do
      false
    else
      true
    end
  end
end
