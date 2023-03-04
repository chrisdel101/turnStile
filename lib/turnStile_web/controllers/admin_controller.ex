defmodule TurnStileWeb.AdminController do
  use TurnStileWeb, :controller

  alias TurnStile.Administration
  alias TurnStile.Administration.Admin

  def index(conn, _params) do
    admins = Administration.list_admins()
    render(conn, "index.html", admins: admins)
  end

  def new(conn, _params) do
       # IO.puts("HELLO")
    role = handle_permission_roles(conn)
    cond do
      role === "owner" ->
        changeset = Administration.create_admin(%Admin{})
        render(conn, "new.html", changeset: changeset)
    end
    IO.puts(role)
    changeset = Administration.change_admin(%Admin{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"admin" => admin_params}) do
    case Administration.create_admin(admin_params) do
      {:ok, admin} ->
        conn
        |> put_flash(:info, "Admin created successfully.")
        |> redirect(to: Routes.admin_path(conn, :show, admin))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    admin = Administration.get_admin!(id)
    render(conn, "show.html", admin: admin)
  end

  def edit(conn, %{"id" => id}) do
    admin = Administration.get_admin!(id)
    changeset = Administration.change_admin(admin)
    render(conn, "edit.html", admin: admin, changeset: changeset)
  end

  def update(conn, %{"id" => id, "admin" => admin_params}) do
    admin = Administration.get_admin!(id)

    case Administration.update_admin(admin, admin_params) do
      {:ok, admin} ->
        conn
        |> put_flash(:info, "Admin updated successfully.")
        |> redirect(to: Routes.admin_path(conn, :show, admin))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", admin: admin, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    admin = Administration.get_admin!(id)
    {:ok, _admin} = Administration.delete_admin(admin)

    conn
    |> put_flash(:info, "Admin deleted successfully.")
    |> redirect(to: Routes.admin_path(conn, :index))
  end

  def handle_permission_roles(conn) do
    current_role = conn.assigns[:current_admin].role
    # IO.inspect(current_role)
    # IO.inspect(to_string(Enum.at(AdminRolesEnum.get_roles, 0)))
    # IO.inspect(to_string(Enum.at(AdminRolesEnum.get_roles, 0)) === current_role)
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

end
