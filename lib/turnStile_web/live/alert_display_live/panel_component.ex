defmodule TurnStileWeb.AlertDisplayLive.PanelComponent do
  use TurnStileWeb, :live_component
  alias TurnStile.Alerts
  alias TurnStile.Alerts.Alert
  alias TurnStileWeb.AlertUtils

  @impl true
  # user opens panel component to alter alert defauls
  def update(props, socket) do
    # IO.inspect(props, label: "props")
    # IO.inspect(socket, label: "socket")

    %{id: user_id, current_employee: _current_employee, user: user} = props

    alerts = Alerts.get_alerts_for_user(user_id)
    # IO.inspect(alerts, label: "alerts")
    # - add some alert default alert attr
    # - default alert to SMS
    sms_attrs =
      Alerts.build_alert_attrs(
        user,
        AlertCategoryTypesMap.get_alert("CUSTOM"),
        AlertFormatTypesMap.get_alert("SMS")
      )

    changeset = Alerts.create_new_alert(%Alert{}, sms_attrs)
    # IO.inspect(changeset, label: "changeset in update")
    {:ok,
     socket
     |> assign(props)
     |> assign(:alerts, alerts)
     |> assign(:title, set_title(props.panel))
     |> assign(:page_title, "Alert Panel")
     |> assign(:changeset, changeset)}
  end

  @impl true
  # only fires on change-handles changing the form based on radio button selection
  def handle_event("radio_changed", params, socket) do
    IO.inspect("toggle_alert_form", label: "toggle_alert_form")
    IO.inspect(params, label: "params")
    alert_params = Map.get(params, :alert) || Map.get(params, "alert")

    # check for change on radio buttons
    if alert_params && Map.has_key?(socket.assigns.changeset, :data) do
      # IO.inspect(alert_params["alert_format"], label: "alert_params")
      # check which type of alert to change
      cond do
        # flip to email form
        alert_params["alert_format"] === AlertFormatTypesMap.get_alert("EMAIL") ->
          # IO.inspect("EMAIL", label: "EMAIL")

          email_attrs =
            Alerts.build_alert_attrs(
              socket.assigns.user,
              AlertCategoryTypesMap.get_alert("CUSTOM"),
              AlertFormatTypesMap.get_alert("EMAIL"),
              from: alert_params["from"],
              to: alert_params["to"],
              title: alert_params["title"],
              body: alert_params["body"]
              # empty_title?: true,
              # empty_body?: true
            )
            IO.inspect(email_attrs, label: "email_attrs")
          # enforce form validations here on email alert
          changeset =
            socket.assigns.changeset.data
            |> Alerts.change_alert(email_attrs, true)

          IO.inspect(changeset, label: "changeset HERE")

          {:noreply, assign(socket, :changeset, changeset)}

        # end
        alert_params["alert_format"] === AlertFormatTypesMap.get_alert("SMS") ->
          IO.inspect("SMS", label: "SMS")

          sms_attrs =
            Alerts.build_alert_attrs(
              socket.assigns.user,
              AlertCategoryTypesMap.get_alert("CUSTOM"),
              AlertFormatTypesMap.get_alert("SMS")
            )

          changeset =
            socket.assigns.changeset.data
            |> Alerts.change_alert(sms_attrs)

          # IO.inspect(changeset, label: "changeset in validate")

          {:noreply, assign(socket, :changeset, changeset)}

        #  end
        true ->
          {:noreply, socket}
      end

      # else
      #   {:noreply, socket}
    end

    # IO.inspect(socket, label: "socket")
  end

  # # displays the custom alert form; called on change
  # def handle_event("dispatch", _params, socket) do
  #   IO.inspect("DISPATCH", label: "params")
  #   changeset = %Alert{}
  #   {:noreply, assign(socket, :changeset, changeset)}
  # end
  def handle_event("change", params, socket) do
    alert_params = Map.get(params, :alert) || Map.get(params, "alert")
    cond do
      # flip to email form
      alert_params["alert_format"] === AlertFormatTypesMap.get_alert("EMAIL") ->
        # IO.inspect("EMAIL", label: "EMAIL")

        email_attrs =
          Alerts.build_alert_attrs(
            socket.assigns.user,
            AlertCategoryTypesMap.get_alert("CUSTOM"),
            AlertFormatTypesMap.get_alert("EMAIL"),
            from: alert_params["from"],
            to: alert_params["to"],
            title: alert_params["title"],
            body: alert_params["body"]
            # empty_title?: true,
            # empty_body?: true
          )
          IO.inspect(email_attrs, label: "email_attrs")
        # enforce form validations here on email alert
        changeset =
          socket.assigns.changeset.data
          |> Alerts.change_alert(email_attrs, true)

        IO.inspect(changeset, label: "changeset HERE")

        {:noreply, assign(socket, :changeset, changeset)}

      # end
      alert_params["alert_format"] === AlertFormatTypesMap.get_alert("SMS") ->
        IO.inspect("SMS", label: "SMS")

        sms_attrs =
          Alerts.build_alert_attrs(
            socket.assigns.user,
            AlertCategoryTypesMap.get_alert("CUSTOM"),
            AlertFormatTypesMap.get_alert("SMS")
          )

        changeset =
          socket.assigns.changeset.data
          |> Alerts.change_alert(sms_attrs)

        # IO.inspect(changeset, label: "changeset in validate")

        {:noreply, assign(socket, :changeset, changeset)}

      #  end
      true ->
        {:noreply, socket}
    end
  end

  # send alert from custom dispatch form
  def handle_event("send_custom_alert", %{"alert" => alert_params}, socket) do
    # IO.inspect(alert_params, label: "alert_params")
    # save alert to DB
    case  AlertUtils.handle_save_alert(socket, socket.assigns.changeset, alert_params) do
      {:ok, alert} ->
        # check alert type to send
        # IO.inspect(alert, label: "alert")
        cond do
          alert.alert_format === AlertFormatTypesMap.get_alert("EMAIL") ->
            # IO.inspect(alert, label: "alert handle_event EmAIl")

            case AlertUtils.send_email_alert(alert) do
              {:ok, _email} ->
                {
                  :noreply,
                  socket
                  # |> assign(:action, "insert")
                  |> put_flash(:success, "Alert sent successfully")
                  # |> push_redirect(to: socket.assigns.return_to)
                }
              {:error, error} ->
                {
                  :noreply,
                  socket
                  # |> assign(:action, "insert")
                  |> put_flash(:error, "Failure in alert send. #{error}")
                  # |> push_redirect(to: socket.assigns.return_to)
                }
            end
          alert.alert_format === AlertFormatTypesMap.get_alert("SMS") ->
            IO.inspect("SMS", label: "SMS")
            case AlertUtils.send_SMS_alert(alert) do
              {:ok, twilio_msg} ->
                IO.inspect(twilio_msg)
                {
                  :noreply,
                  socket
                  # |> assign(:action, "insert")
                  |> put_flash(:success, "Alert sent successfully")
                  # |> push_redirect(to: socket.assigns.return_to)
                }
              # handle twilio errors
              {:error, error_map, error_code} ->
                {
                  :noreply,
                  socket
                  # |> assign(:action, "insert")
                  |> put_flash(:error, "Failure in alert send. #{error_map["message"]}. Code: #{error_code}")
                  # |> push_redirect(to: socket.assigns.return_to)
                }
              {:error, error} ->
                {
                  :noreply,
                  socket
                  # |> assign(:action, "insert")
                  |> put_flash(:error, "Failure in alert send. #{error}")
                  # |> push_redirect(to: socket.assigns.return_to)
                }
              end
          true ->
            {
              :noreply,
              socket
              # |> assign(:action, "insert")
              |> put_flash(:error, "Unknown alert format type. Only email or SMS are alllowed. Try again or contact support.")
              # |> push_redirect(to: socket.assigns.return_to)
            }
        end

      {:error, changeset} when is_map(changeset) ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> put_flash(:error, "Alert Not created successfully")}

      {:error, error} when is_binary(error) ->
        {:noreply,
         socket
         |> put_flash(:error, error)}
    end
  end

  defp set_title(panel_prop) do
    if panel_prop === "history" do
      "Alert History"
    else
      "Alert Dispatch"
    end
  end
end
