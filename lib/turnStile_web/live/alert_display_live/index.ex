defmodule TurnStileWeb.AlertDisplayLive.Index do
  use TurnStileWeb, :live_view

  alias TurnStile.Alert
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
    |> assign(:page_title, "Edit Alert display")
    |> assign(:alert_display, Alerts.get_alert_display!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Alert display")
    |> assign(:alert_display, %Alert{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Alerts")
    |> assign(:alert_display, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    alert_display = Alerts.get_alert_display!(id)
    {:ok, _} = Alerts.delete_alert_display(alert_display)

    {:noreply, assign(socket, :alerts, list_alerts())}
  end

  defp list_alerts do
    Alerts.list_alerts()
  end
end
