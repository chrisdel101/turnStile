defmodule TurnStileWeb.AdminRegistrationController do
  use TurnStileWeb, :controller

  alias TurnStile.Administration
  alias TurnStile.Administration.Admin
  alias TurnStileWeb.AdminAuth
  alias TurnStileWeb.OrganizationController

  def new(conn, _params) do
    changeset = Administration.change_admin_registration(%Admin{})
    organization_id = conn.path_params["id"]
    # IO.inspect(conn.path_params["id"])
    render(conn, "new.html", changeset: changeset, organization_id: organization_id)
  end

  def create(conn, %{"admin" => admin_params}) do
    IO.inspect("Admin: create")
    IO.inspect(%{"admin" => admin_params})
    current_admin = conn.assigns[:current_admin]
    # setup organization process
    if !current_admin do
      create_setup_owner(conn, %{"admin" => admin_params})
    end

    # check admin doing the creating permissions
    current_user_permission = TurnStile.Utils.get_permissions_level_int(current_admin.role)
    # check level of user being createdd
    registrant_permissions =
      TurnStile.Utils.get_permissions_level_int(Map.get(admin_params, "role"))

    # make sure adequate perms - only register permissions level >= self
    if registrant_permissions > current_user_permission do
      changeset = Administration.change_admin_registration(%Admin{}, admin_params)

      conn
      # if admin does not have permissions - flash and re-render
      |> put_flash(:error, "Invalid Permssions to create that user")
      |> render("new.html", changeset: changeset)
    end

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

  # create first user as owner
  defp create_setup_owner(conn, %{"admin" => admin_params}) do
    # confirm org exists
    organization_id = conn.path_params["id"]
    IO.inspect("ORG ID: #{organization_id}")
    org_exists? = TurnStile.Company.get_organization(organization_id)

    if org_exists? do
      # confirm org has no members/ is not setup
      members? = OrganizationController.organization_has_members?(organization_id)
      if members? do
        conn
        |> put_flash(:error, "Organization already setup. Login is required")
        |> redirect(to: Routes.page_path(conn, :index))
      else
        # create owner
        case Administration.register_admin(admin_params) do
          {:ok, admin} ->
            {:ok, _} =
              Administration.deliver_admin_confirmation_instructions(
                admin,
                &Routes.admin_confirmation_url(conn, :edit, &1)
              )

            conn
            |> put_flash(:info, "Setup Owner created successfully.")
            |> AdminAuth.log_in_admin(admin)

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "new.html", changeset: changeset)
        end
      end
    else
      conn
      |> put_flash(:error, "Organization does not exist")
      |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end
