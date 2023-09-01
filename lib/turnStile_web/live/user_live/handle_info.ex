defmodule TurnStileWeb.UserLive.Index.HandleInfo do
  use Phoenix.Component
  # use TurnStileWeb, :live_component
  alias TurnStile.Utils
  alias TurnStileWeb.UserLive.DisplayListComponent
  alias TurnStileWeb.AlertController
  alias TurnStile.Patients

  # mutli user match recieived from twilio
  # comes from alert controller via PUBSUB
  # non_idle_matching_users is a list of active user with active state
  def handle_mutli_match_twilio_users(%{mutli_match_twilio_users: users_match_phone_list}, socket) do
    # users match org_id, is_active?, and active state
    matched_users_tuples = match_users_to_organization(users_match_phone_list, socket)
    # combine w default empty list
    unmtached_users = Enum.concat(socket.assigns.unmatched_SMS_users, matched_users_tuples)
    # IO.inspect(unmtached_users, label: "PUBSUB: indexed_tuples LIST in handle_info")
    {:noreply,
    socket
    |> assign(:unmatched_SMS_users, unmtached_users)
     |> assign(
       :popup_hero_title,
       "Multi-User Match - Employee Attention Required ."
     )
     |> assign(
       :popup_hero_body,
       "Incoming user response matches  multiple users accounts in your organizaion. Review to reconcile the issue."
     )}
  end

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
  def handle_send_response_params(%{send_response_params: %{
    twilio_params: twilio_params,
    conn: conn
  }}, socket) do
    IO.inspect(twilio_params, label: "PUBSUB: message in handle_info")
    AlertController.send_computed_SMS_system_response(conn, twilio_params)


    {:noreply, socket}
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
    IO.puts(
      "index handle info: {:users_found, %{'existing_users_found' => existing_users_found}}"
    )

    # IO.inspect("UUUUUUUU", label: "message in handle_info")
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
  defp match_users_to_organization(users_list, socket) do
    # IO.inspect(indexed_tuples, label: "PUBSUB: indexed_tuples LIST in handle_info")
    current_employee = socket.assigns.current_employee
    organization_id = current_employee.current_organization_login_id
    # get users match current org
    users_match_org_list = Enum.filter(users_list, fn x -> x.organization_id === organization_id end)
    # get active matching users
    active_pending_users = Utils.filter_maps_list_by_truthy(users_match_org_list, "is_active?")
    # IO.inspect(users_match_org_list, label: "match_users_to_organization users_match_org_list")
     # check non-idle state
    f = &is_user_alert_status_idle?/1
    # loop over all users - reject user idle w states
    non_idle_users = Enum.reject(active_pending_users, f)
    # IO.inspect(non_idle_users, label: "non_idle_users")
    # make into list w index
    # indexed_tuples = Enum.with_index(non_idle_users)
    # IO.inspect(indexed_tuples, label: "PUBSUB: indexed_tuples LIST in handle_info")
    # users are formed like {%{...}, 0}
    non_idle_users
  end
  defp is_user_alert_status_idle?(user) do
    # check for both syntax types
    user_alert_status = Map.get(user, "user_alert_status")
 ||  Map.get(user, :user_alert_status)
    # check if it matches one of the invalid states
    user_alert_status in [
      UserAlertStatusTypesMap.get_user_status("UNALERTED"),
      UserAlertStatusTypesMap.get_user_status("CANCELLED"),
      UserAlertStatusTypesMap.get_user_status("EXPIRED")]
  end
end
