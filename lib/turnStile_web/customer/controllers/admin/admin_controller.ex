defmodule TurnStileWeb.AdminController do
  use TurnStileWeb, :controller

  alias TurnStile.Staff
  alias TurnStile.Staff.Admin

  def index(conn, _params) do
    organization_id = conn.params["organization_id"]
    if !organization_id do
      conn
      |> put_flash(:error, "An Organization ID error ocurred. Make sure it exists.")
      |> redirect(to: Routes.organization_path(conn, :index))
    end
    admins = Staff.list_admins_by_organization(organization_id)
    # get admins in this org
    render(conn, "index.html", admins: admins, organization_id: organization_id)
  end

  def new(conn, _params) do
       # IO.puts("HELLO")
    role = assign_permission_role(conn)
    cond do
      role === "owner" ->
        changeset = Staff.create_admin(%Admin{})
        render(conn, "new.html", changeset: changeset)
    end
    # IO.puts(role)
    changeset = Staff.change_admin(%Admin{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"admin" => admin_params}) do
    case Staff.create_admin(admin_params) do
      {:ok, admin} ->
        conn
        |> put_flash(:info, "Admin created successfully.")
        |> redirect(to: Routes.admin_path(conn, :show, admin))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    admin = Staff.get_admin!(id)
    render(conn, "show.html", admin: admin)
  end

  def edit(conn, %{"id" => id}) do
    admin = Staff.get_admin!(id)
    changeset = Staff.change_admin(admin)
    render(conn, "edit.html", admin: admin, changeset: changeset)
  end

  def update(conn, %{"id" => id, "admin" => admin_params}) do
    admin = Staff.get_admin!(id)

    case Staff.update_admin(admin, admin_params) do
      {:ok, admin} ->
        conn
        |> put_flash(:info, "Admin updated successfully.")
        |> redirect(to: Routes.admin_path(conn, :show, admin))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", admin: admin, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    admin = Staff.get_admin!(id)
    {:ok, _admin} = Staff.delete_admin(admin)

    conn
    |> put_flash(:info, "Admin deleted successfully.")
    |> redirect(to: Routes.admin_path(conn, :index))
  end
# takes the form value maps to correct permission role
  def assign_permission_role(conn) do
    current_role = conn.assigns[:current_admin].role

    cond do
      # owner
      current_role === to_string(Enum.at(AdminRolesEnum.get_roles, 0))  ->
        to_string(Enum.at(AdminRolesEnum.get_roles, 0))
      # admin
      current_role === to_string(Enum.at(AdminRolesEnum.get_roles, 1))  ->
        to_string(Enum.at(AdminRolesEnum.get_roles, 1))
      # developer
      current_role === to_string(Enum.at(AdminRolesEnum.get_roles, 2))  ->
        to_string(Enum.at(AdminRolesEnum.get_roles, 2))


    end
  end

  def admin_is_in_organization?(conn, _opts) do
    # organization_id = organization_id = conn.params["id"]
    # check

    conn
    # {:ok, _admin} = Staff.delete_admin(admin)

    # conn
    # |> put_flash(:info, "Admin deleted successfully.")
    # |> redirect(to: Routes.admin_path(conn, :index))
  end
end
