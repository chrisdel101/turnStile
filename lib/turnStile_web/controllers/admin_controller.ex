defmodule TurnStileWeb.AdminController do
  use TurnStileWeb, :controller

  alias TurnStile.Operations
  alias TurnStile.Operations.Admin
  # new & create removed; use registration

  # /admins - list all admins
  def index(conn, _params) do
    admins = Operations.list_admins()
    render(conn, "index.html", admins: admins)
  end

  def home(conn, _params) do
    render(conn, "home.html")
  end


  def show(conn, %{"id" => id}) do
    admin = Operations.get_admin!(id)
    render(conn, "show.html", admin: admin)
  end

  def edit(conn, %{"id" => id}) do
    admin = Operations.get_admin!(id)
    changeset = Operations.change_admin(admin)
    render(conn, "edit.html", admin: admin, changeset: changeset)
  end

  def update(conn, %{"id" => id, "admin" => admin_params}) do
    admin = Operations.get_admin!(id)

    case Operations.update_admin(admin, admin_params) do
      {:ok, admin} ->
        conn
        |> put_flash(:info, "Admin updated successfully.")
        |> redirect(to: Routes.admin_path(conn, :show, admin))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", admin: admin, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    admin = Operations.get_admin!(id)
    {:ok, _admin} = Operations.delete_admin(admin)

    conn
    |> put_flash(:info, "Admin deleted successfully.")
    |> redirect(to: Routes.admin_path(conn, :index))
  end
end
