defmodule TurnStileWeb.SetupController do
  use TurnStileWeb, :controller

  def new(conn, _params) do
    conn
    |> render("new.html")
  end
end
