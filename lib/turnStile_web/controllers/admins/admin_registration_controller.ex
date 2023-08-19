defmodule TurnStileWeb.AdminRegistrationController do
  use TurnStileWeb, :controller

  alias TurnStile.Operations
  alias TurnStile.Operations.Admin

  def new(conn, _params) do
    changeset = Operations.change_admin_registration(%Admin{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(_conn, %{"admin" =>_admin_params}) do
    # current_admin = conn.assigns[:current_admin]
    # # check admin permissions
    # current_admin_permission = TurnStile.Utils.get_admin_permissions_level(current_admin.role)
    # # check level of admin being createdd
    # registrant_permissions =
    #   TurnStile.Utils.get_admin_permissions_level(Map.get(admin_params, "role"))
    # # check perms - only register permissions level >= self -> lower numb is higher perms
    # if registrant_permissions >
    # current_admin_permission do
    #   conn
    #   #  Invalid persmission - flash and re-render
    #   |> put_flash(:error, "Invalid Permssions to create that user")
    #   |> render("new.html", changeset: Operations.change_admin_registration(%Admin{}, admin_params))
    # else
    #   # if permissions okay
    #   case Operations.register_admin(admin_params) do
    #     {:ok, admin} ->
    #       {:ok, _} =
    #         Operations.deliver_admin_confirmation_instructions(
    #           admin,
    #           &Routes.admin_confirmation_url(conn, :edit, &1)
    #         )

    #       conn
    #       |> put_flash(:info, "Admin created successfully.")
    #       |> AdminAuth.log_in_admin(admin)

    #     {:error, %Ecto.Changeset{} = changeset} ->
    #       render(conn, "new.html", changeset: changeset)
    #   end
    # end
  end
end
