defmodule TurnStileWeb.UserLive.Index.HandleInfo do
  use Phoenix.Component
  # use TurnStileWeb, :live_component
  alias TurnStile.Utils
  alias TurnStileWeb.AlertController
  alias TurnStile.Patients
  # alias TurnStile.Alerts
  # alias TurnStile.Alerts.Alert
  # alias TurnStileWeb.AlertUtils


  # receives pubsub subscription from user self registation form
  # TODO: maybe optimize https://hexdocs.pm/phoenix_live_view/dom-patching.html#temporary-assigns
  def handle_user_registation_form({:user_registation_form, %{user_params: user_params}}, socket) do
    # adding msgs one at a time, starting with empty list
    index = length(socket.assigns.user_registration_messages)
    # use list length before add to get index
    currrent_message = %{index => user_params}
    # add incoming message to storage
    messages = Enum.concat(socket.assigns.user_registration_messages, [currrent_message])
    # msg are formed like %{"0" => %{...}}

    {:noreply,
     socket
     |> assign(:user_registration_messages, messages)
     |> assign(:popup_message_title, "User Registration Form Recieved")
     |> assign(
       :popup_message_body,
       "The following user registration form was recieved. Please review and accept the user to register them."
     )}
  end
  def handle_user_alert_status(%{user_alert_status: _user_alert_status}, socket, opts) do
    # IO.inspect(user_alert_status, label: "PUBSUB: message in handle_info")

    users =
      Patients.filter_active_users_x_mins_past_last_update(
        socket.assigns.current_employee.current_organization_login_id,
        Keyword.get(opts, :filter_active_users_mins)
      )

    {:noreply, assign(socket, :users, users)}
  end

  # comes via send :upsert from :new
  def handle_existing_users_from_upsert(
        %{"existing_users" => existing_users, "user_changeset" => user_changeset},
        socket
      ) do
    socket =
      socket
      |> assign(:existing_users, existing_users)
      |> assign(:user_changeset, user_changeset)

    # IO.inspect(socket.assign., label: "PUBSUB EX: message in handle_info")
    # IO.inspect(socket.assigns.user_changeset, label: "SEND: message in handle_info")

    {:noreply, socket}
  end

  # pubsub comes thru subscribe in mount
  def handle_update(:update, socket, opts) do
    IO.puts("index handle info: :update")
    # update_and_reschedule and call
    if connected?(socket), do: Process.send_after(self(), :update,  Keyword.get(opts, :interval))

    users =
      Patients.filter_active_users_x_mins_past_last_update(
        socket.assigns.current_employee.current_organization_login_id,
        Keyword.get(opts, :filter_active_users_mins)
      )

    # IO.inspect(users, label: "update info")
    {:noreply, assign(socket, :users, users)}
  end

  # called from :search; when search results are found
  def handle_users_found_from_search({:users_found, %{"existing_users_found" => existing_users_found}}, socket) do

    # IO.inspect(existing_users_found, label: "message in handle_info")
    # call update to refresh state on :display
    send_update(DisplayListComponent, id: "display")
    {:noreply, assign(socket, :existing_users_found, existing_users_found)}
    # IO.inspect(socket.assigns.existing_users_found, label: "message in handle_info rAFTER")
  end

  # called from :new match is found
  # sending found users list to :display
  def handle_users_found_from_new(
        {:users_found,
         %{
           existing_users_found: existing_users_found,
           user_changeset: user_changeset,
           redirect_to: redirect_to
         }},
        socket
      ) do
    socket =
      socket
      |> assign(:existing_users_found, existing_users_found)
      |> assign(:user_changeset, user_changeset)

    IO.puts("index handle_info: sent from upsert send(): changeset and ext users")
    # IO.inspect(user_changeset, label: "message in handle_info")
    # IO.inspect("VVVVVVVVVV4", label: "message in handle_info")
    # redirect to :display component
    {:noreply,
     socket
     |> push_patch(to: redirect_to)}

    # {:noreply, socket}
  end

  # called from :display display when going back to original user
  # - redirect back to upsert
  def handle_reject_existing_users(
        {:reject_existing_users, %{user_changeset: user_changeset, redirect_to: redirect_to}},
        socket
      ) do
    socket =
      socket
      |> assign(:user_changeset, user_changeset)

    # IO.inspect(socket.assigns.user_changeset.data, label: "message in handle_info")
    # IO.inspect(user_changeset, label: "message in handle_info")
    # IO.inspect("VVVVVVVVVV4", label: "message in handle_info")
    # redirect to :display component
    {:noreply,
     socket
     |> push_patch(to: redirect_to)}
  end
end
