defmodule TurnStileWeb.PopUpBlock do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @defmodule """
  PopUpBlock Live Component
  - single item not in a list
  - for use when only a sinlge block is required
  """
  def render(assigns) do
    message_id = "message-#{assigns.id}"
    ~H"""
    <div id={message_id}class="popup  alert alert-danger">
    <div class="popup-header">
     <h3><%= assigns[:popup_title] %></h3>
      <p>
        <%= assigns[:popup_body] %>
      </p>
    </div>
      <div class="popup-body">
        <div class="pop-col">
        </div>
        <div class="pop-col">
          <button phx-click="user_alert_match_review" title="Review user before accept">Review</button>
          <button phx-click="user_alert_match_reject"  title="Reject and delete incoming response" data-confirm="This cannot be undone. Are you sure?">Reject</button>
        </div>
        <div class="pop-col">
        <a href="#" class="phx-modal-close" phx-click={hide_popup(message_id)} title="Ignore Message">✖</a>
        </div>
      </div>
    </div>
    """
    end
  # @impl
  # def handle_event("send_data_to_parent", %{value: _value}, socket) do
  #   # IO.inspect(socket.assigns, label: "send_data_to_parent")
  #   send_data_to_parent(socket)
  #   {:noreply, socket}
  # end
  def hide_popup(popup_id) do
    %JS{}
    |> JS.hide(transition: "fade-out", to: "##{popup_id}")
  end
end
