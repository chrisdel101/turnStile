defmodule TurnStileWeb.PopUpItem do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @defmodule """
  PopUpItem Live Component
  - single item within a list
  - can be mutltiple at at time on page
  """

  def render(assigns) do
    message_id = "message-#{assigns.id}"
    ~H"""
    <div id={message_id}class="popup  alert alert-info">
    <div class="popup-header">
    <h3><%= assigns[:popup_title] %></h3>
    <p>
      <%= assigns[:popup_body] %>
    </p>
    </div>
    <div class="popup-body">
      <div class="pop-col">
        <p>Message #<%= assigns.id %></p>
      <%= parse_popup_data(assigns[:popup_data]) %>
      </div>
      <div class="pop-col">
        <button phx-click="user_registration_data_accept" value={assigns.id} title="Review message before submit">Review</button>
        <button phx-click="user_registration_data_reject" value={assigns.id} title="Reject and delete message" data-confirm="This cannot be undone. Are you sure?">Reject</button>
      </div>
      <div class="pop-col">
       <a href="#" class="phx-modal-close" phx-click={hide_popup(message_id)} title="Ignore Message">✖</a>
      </div>
    </div>
    </div>
    """
  end
  def hide_popup(popup_id) do
    %JS{}
    |> JS.hide(transition: "fade-out", to: "##{popup_id}")
  end
  defp parse_popup_data(nil), do: nil
  defp parse_popup_data(popup_conent) when is_map(popup_conent) do
    "#{popup_conent.last_name}, #{popup_conent.first_name}"
  end
  defp parse_popup_data(popup_conent) when is_binary(popup_conent) do
    popup_conent
  end
end
