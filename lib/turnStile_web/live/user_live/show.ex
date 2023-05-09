defmodule TurnStileWeb.UserLive.Show do
  use TurnStileWeb, :live_view

  alias TurnStile.Patients

  @impl true
  def mount(_params, _session, socket) do
    IO.puts("HERE11")
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"employee_id" => employee_id, "organization_id" => organization_id, "user_id" => user_id}, _, socket) do
    IO.puts("HERE2")
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:user, Patients.get_user!(user_id))
     |> assign(employee_id: employee_id, organization_id: organization_id)}
  end

  defp page_title(:show), do: "Show User"
  defp page_title(:edit), do: "Edit User"
end
