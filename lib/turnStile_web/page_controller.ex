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
    # IO.inspect("Seesions at the top")
    # IO.inspect(get_session(conn))
    # if canceled, delete sessions
    if Map.has_key?(conn.query_params, "empty") && conn.query_params["empty"] == "true" do
          # IO.inspect("Seesions after delete")
          IO.inspect(get_session(conn))

          employees? = runSetupCheck()
          conn
          |> TurnStile.Utils.empty_sesssion_params("org_params")
          |> assign(:employees?, employees?)
          |> render("index.html")
    else
      employees? = runSetupCheck()
      conn
      |> assign(:employees?, employees?)
      |> render("index.html")

    end
  end



end
