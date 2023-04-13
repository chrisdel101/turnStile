defmodule TurnStileWeb.UserController do
  use TurnStileWeb, :controller

  alias TurnStile.Patients
  alias TurnStile.Patients.User

  def index(conn, _params) do
    IO.inspect(conn)
    users = Patients.list_users()
    organization_id = conn.params["organization_id"]
    employee_id = conn.params["employee_id"]
    render(conn, "index.html", users: users, employee_id: employee_id, organization_id: organization_id)
  end

  def new(conn, _params) do
    changeset = Patients.change_user(%User{})
    organization_id = conn.params["organization_id"]
    employee_id = conn.params["employee_id"]
    render(conn, "new.html", changeset: changeset, employee_id: employee_id, organization_id: organization_id)
  end

  def create(conn, %{"user" => user_params}) do
    organization_id = conn.params["organization_id"]
    employee_id = conn.params["employee_id"]
    IO.inspect("user_params")
    IO.inspect(organization_id)
    IO.inspect(employee_id)
    case Patients.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.organization_employee_user_path(conn, :show, organization_id, employee_id, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Patients.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Patients.get_user!(id)
    changeset = Patients.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Patients.get_user!(id)

    case Patients.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.organization_employee_user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Patients.get_user!(id)
    {:ok, _user} = Patients.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.organization_employee_user_path(conn, :index))
  end
end
