defmodule TurnStileWeb.PageController do
  use TurnStileWeb, :controller
  alias TurnStile.Staff
  # import Phoenix.LiveView
  # import Phoenix.LiveView.Utils

  # check to see if app is setup yet
  defp runSetupCheck() do
    # check if any admins exist
    admins? = Staff.list_all_admins()
    if length(admins?) === 0 do
      false
      # show setup menu
    else
      true
      # show admin menu
    end
  end

  def index(conn, _params) do
    admins? = runSetupCheck()
    conn
    |> assign(:admins?, admins?)
    |> render("index.html")
  end
end
