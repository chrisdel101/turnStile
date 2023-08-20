defmodule TurnStileWeb.UserRegistrationController do
 use TurnStileWeb, :controller
  @moduledoc """
   UserRegistrationController
 - renders the template for users given a verification code to self register
 """

 alias TurnStileWeb.UserAuth

 def new(conn, %{"token" => token} = params) do
  IO.inspect(conn)
   changeset = TurnStile.Patients.create_user(%{})
   assigns  = conn.assigns
   assigns = Map.put(assigns, :action, Routes.user_registration_path(conn, :handle_create, 1))
   conn = Map.put(conn, :assigns, assigns)
   conn
   |> render("new.html", changeset: changeset, token: token)
 end

 def handle_create(conn, %{"user" => user_params}) do
  IO.inspect(user_params, label: "user_params")
  conn
  |> redirect(to: "/")
 end

 def delete(conn, _params) do
   conn
   |> put_flash(:info, "Logged out successfully.")
   |> UserAuth.log_out_user()
 end

end
