defmodule TurnStileWeb.AdminRegistrationController do
  use TurnStileWeb, :controller

  alias TurnStile.Administration
  alias TurnStile.Administration.Admin
  alias TurnStileWeb.AdminAuth


  def new(conn, _params) do
    changeset = Administration.change_admin_registration(%Admin{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"admin" => admin_params}) do
    IO.inspect("Admin: create")
    # IO.inspect(%{"admin" => admin_params})
    current_admin = conn.assigns[:current_admin]
    current_user_permission = TurnStile.Utils.define_permissions_level(current_admin.role)
    registrant_permissions = TurnStile.Utils.define_permissions_level(Map.get(admin_params, "role"))
    # if admin does not have permissions - flash and re-render
    cond do
      # current user can only register permissions level >= self
      registrant_permissions > current_user_permission ->
        changeset = Administration.change_admin_registration(%Admin{}, admin_params)
      conn
        |> put_flash(:error, "Invalid Permssions to create that user")
        |> render("new.html", changeset: changeset)
    end
    # if p_level
  #  if current_admin
    case Administration.register_admin(admin_params) do
      {:ok, admin} ->
        {:ok, _} =
          Administration.deliver_admin_confirmation_instructions(
            admin,
            &Routes.admin_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "Admin created successfully.")
        |> AdminAuth.log_in_admin(admin)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

end
