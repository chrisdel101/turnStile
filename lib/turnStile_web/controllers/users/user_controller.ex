defmodule TurnStileWeb.UserController do
  use TurnStileWeb, :controller

  alias TurnStile.Patients
  alias TurnStile.Patients.User

  def index(conn, _params) do
    # IO.inspect(conn)
    changeset = Patients.change_user(%User{})
    users = Patients.list_users()
    render(conn, "index.html", users: users, changeset: changeset)
  end

  def new(conn, _params) do
    changeset = Patients.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    current_employee = conn.assigns[:current_employee]
    # manually add employee_id
    user_params = Map.put(user_params, "employee_id", current_employee.id)
    IO.inspect(user_params, label: "user_params")
    conn
    |> maybe_employee_exists()
    case Patients.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.organization_employee_user_path(conn, :show, current_employee.dcurrent_organization_login_id, current_employee.id, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Patients.get_user(id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Patients.get_user(id)
    changeset = Patients.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Patients.get_user(id)
    current_employee = conn.assigns[:current_employee]
    conn
    |> maybe_employee_exists()
    case Patients.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.organization_employee_user_path(conn, :show, current_employee.dcurrent_organization_login_id, current_employee.id, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Patients.get_user(id)
    current_employee = conn.assigns[:current_employee]
    conn
    |> maybe_employee_exists()
    {:ok, _user} = Patients.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.organization_employee_user_path(conn, :index, current_employee.dcurrent_organization_login_id, current_employee.id))
  end
  # make sure current employee exists
  defp maybe_employee_exists(conn) do
    case conn.assigns[:current_employee] do
      nil ->
        conn
        |> put_flash(:error, "A session error occured. You must be logged in to access this page. Make sure you are logged in and try again.")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()
      _ ->
        conn
      end
  end
end
