defmodule TurnStileWeb.AlertDisplayLive.PanelComponent do
  use TurnStileWeb, :live_component

  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert

  @impl true
  def update(props, socket) do
    # IO.inspect(props, label: "props")
    # IO.inspect(socket, label: "socket")

    %{id: user_id} = props
    alerts = Alerts.get_alerts_for_user(user_id)
    # IO.inspect(alerts, label: "alerts"
    {:ok,
     socket
     |> assign(props)
     |> assign(:alerts, alerts)
     |> assign(:form_title, "Alerts Dispatch")
     |> assign(:title, set_title(props.panel))
     |> assign(:page_title, "Alert Panel")
     |> assign(:changeset, Alerts.change_alert(%Alert{}))}
  end

  @impl true
  def handle_event(any,%{"alert" => alert_params}, socket) do
    IO.inspect(any, label: "any")
  end
  def handle_event("validate", %{"alert" => alert_params}, socket) do
    IO.inspect("validate", label: "validate")
    changeset =
      socket.assigns.alert
      |> Alerts.change_alert(alert_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("dispatch", params, socket) do
   IO.inspect(params, label: "params")
   changeset = %Alert{}
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"alert" => alert_params}, socket) do
    save_alert(socket, socket.assigns.action, alert_params)
  end

  defp save_alert(socket, :edit, alert_params) do
    case Alerts.update_alert(socket.assigns.alert, alert_params) do
      {:ok, _alert} ->
        {:noreply,
         socket
         |> put_flash(:info, "Alert updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp set_title(panel_prop) do
    if panel_prop === "history" do
      "Alert History"
    else
      "Alert Dispatch"
    end
  end


  defp save_alert(socket, :new, alert_params) do
    case Alerts.create_alert(alert_params) do
      {:ok, _alert} ->
        {:noreply,
         socket
         |> put_flash(:info, "Alert created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
