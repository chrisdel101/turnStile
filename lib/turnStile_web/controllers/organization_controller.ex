defmodule TurnStileWeb.OrganizationController do
  use TurnStileWeb, :controller

  alias TurnStile.Company
  alias TurnStile.Company.Organization

  def index(conn, _params) do
    # only app in-company app developers can see this
    organizations = Company.list_organizations()
    render(conn, "index.html", organizations: organizations)
  end

  def search(conn, _params) do
    changeset = Company.change_organization(%Organization{})
    organizations = Company.list_organizations()
    IO.inspect("HERE")
    IO.inspect(organizations)
    render(conn, "search.html", changeset: changeset, organizations: organizations)
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
    # param is ID
    if TurnStile.Utils.is_digit(param) do
      organization = Company.get_organization!(param)
      reload_with_name_rest(conn, organization)
    else
      organization = Company.get_organization_by_name!(param)
      render(conn, "show.html", organization: organization)
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
  defp reload_with_name_rest(conn, organization_map) do
    redirect(conn, to: "/organizations/#{organization_map.slug}")
  end
  # check if org has members
  defp is_organiztion_setup do
    IO.inpspect(Company.check_organization())
  end
end
