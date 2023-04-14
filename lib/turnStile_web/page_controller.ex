defmodule TurnStileWeb.PageController do
  use TurnStileWeb, :controller
  alias TurnStile.Staff
  # import Phoenix.LiveView
  # import Phoenix.LiveView.Utils

  # check to see if app is setup yet
  defp runSetupCheck() do
    # check if any employees exist
    employees? = Staff.list_all_employees()
    if length(employees?) === 0 do
      false
      # show setup menu
    else
      true
      # show employee menu
    end
  end

  def index(conn, _params) do
    # if employee logged in, redirect to organuzation show
    if conn.assigns[:current_employee] do
      conn
      |> redirect(to: Routes.organization_path(conn, :show, conn.assigns[:current_employee].organization_id))
    end
    employees? = runSetupCheck()
    conn
    |> assign(:employees?, employees?)
    |> render("index.html")
  end
end
