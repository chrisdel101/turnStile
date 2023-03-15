defmodule TurnStileWeb.PageController do
  use TurnStileWeb, :controller
  alias TurnStile.Administration
  # import Phoenix.LiveView
  # import Phoenix.LiveView.Utils

  # check to see if app is setup yet
  defp runSetupCheck() do
    # check if any admins exist
    admins? = Administration.list_admins()
    if length(admins?) === 0 do
      false
      # show setup menu
    else
      true
      # show admin/employee menu
    end
  end

  def index(conn, _params) do
    admins? = runSetupCheck()
    conn
    |> assign(:admins?, admins?)
    |> render("index.html")
  end
end
