defmodule TurnStileWeb.AdminRegistrationController do
  use TurnStileWeb, :controller

  alias TurnStile.Administration
  alias TurnStile.Administration.Admin
  alias TurnStileWeb.AdminAuth
  alias TurnStileWeb.OrganizationController

  def new(conn, _params) do
    changeset = Administration.change_admin_registration(%Admin{})
    organization_id = conn.path_params["id"]
    render(conn, "new.html", changeset: changeset, organization_id: organization_id)
  end

  def create(conn, %{"admin" => admin_params}) do
    current_admin = conn.assigns[:current_admin]
    # setup organization process
    if !current_admin do
      setup_initial_owner(conn, %{"admin" => admin_params})
    else
      organization_id = conn.path_params["id"]
      if !organization_id do
        conn
        |> put_flash(:error, "An Organization ID error ocurred. Make sure it exists.")
        |> redirect(to: Routes.organization_path(conn, :index))
      end
      organizations? = TurnStile.Company.check_organization_exists_by_id(organization_id)
      if length(organizations?) != 1 do
        conn
        |> put_flash(:info, "An Organization error ocurred. Make sure it exists.")
        |> redirect(to: Routes.organization_path(conn, :new))
      else
        # check admin doing the creating permissions
        current_user_permission = TurnStile.Utils.get_permissions_level_int(current_admin.role)
        # check level of user being createdd
        registrant_permissions =
          TurnStile.Utils.get_permissions_level_int(Map.get(admin_params, "role"))

        # make sure adequate perms - only register permissions level >= self
        if registrant_permissions >
        current_user_permission do

          changeset = Administration.change_admin_registration(%Admin{}, admin_params)

          conn
          # if admin does not have permissions - flash and re-render
          |> put_flash(:error, "Invalid Permssions to create that user")
          |> render("new.html", changeset: changeset, organization_id: organization_id)
        else
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
              render(conn, "new.html", changeset: changeset, organization_id: organization_id)
          end
        end
      # end
      end
      # check admin doing the creating permissions
      current_user_permission = TurnStile.Utils.get_permissions_level_int(current_admin.role)
      # check level of user being createdd
      registrant_permissions =
        TurnStile.Utils.get_permissions_level_int(Map.get(admin_params, "role"))

      # make sure adequate perms - only register permissions level >= self
      if registrant_permissions >
      current_user_permission do

        changeset = Administration.change_admin_registration(%Admin{}, admin_params)

        conn
        # if admin does not have permissions - flash and re-render
        |> put_flash(:error, "Invalid Permssions to create that user")
        |> render("new.html", changeset: changeset)
      end
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
  defp setup_initial_owner(conn, %{"admin" => admin_params}) do
    # confirm org exists
    organization_id = conn.path_params["id"]
    organizations? = TurnStile.Company.check_organization_exists_by_id(organization_id)
    # check if org already exis
    if length(organizations?) === 1 do
      # confirm org has no members/ so is not setup
      members? = OrganizationController.organization_has_members?(organization_id)
      # if member, send error
      if members? do
        conn
        |> put_flash(:error, "Organization already setup. Login is required")
        |> redirect(to: Routes.page_path(conn, :index))
       # if no members, allow setup
      else
        # add organization_id to params
        admin_params = Map.put(admin_params, "organization_id", organization_id)
        # create owner
        case Administration.register_admin(admin_params) do
          {:ok, admin} ->
            {:ok, _} =
              Administration.deliver_admin_confirmation_instructions(
                admin,
                &Routes.admin_confirmation_url(conn, :edit, organization_id, &1)
              )

            conn
            |> put_flash(:info, "Setup Owner created successfully.")
            |> AdminAuth.log_in_admin(admin)

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "new.html", changeset: changeset, organization_id: organization_id)
        end
      end
    else
      conn
      |> put_flash(:error, "Organization does not exist")
      |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end
