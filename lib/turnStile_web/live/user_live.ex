defmodule TurnStileWeb.UserLive do
  use TurnStileWeb, :live_view


  alias TurnStile.Patients
  alias TurnStile.Patients.User
  def mount(_params, _session, socket) do
    changeset = Patients.change_user(%User{})
    users = Patients.list_users()

    socket = assign(socket, users: users, changeset: changeset, title: "SOME TITLE")

    {:ok, socket}
  end
  def index(conn, _params) do
    changeset = Patients.change_user(%User{})
    users = Patients.list_users()
    render(conn, "index.html", users: users, changeset: changeset, title: "SOME TITLE")
  end
end
