defmodule TurnStileWeb.AlertLive.Index do
  use TurnStileWeb, :live_view

  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :alerts, list_alerts())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Alert")
    |> assign(:alert, Alerts.get_alert!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Alert")
    |> assign(:alert, %Alert{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Alerts")
    |> assign(:alert, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    alert = Alerts.get_alert!(id)
    {:ok, _} = Alerts.delete_alert(alert)

    {:noreply, assign(socket, :alerts, list_alerts())}
  end

  defp list_alerts do
    Alerts.list_alerts()
  end
end
