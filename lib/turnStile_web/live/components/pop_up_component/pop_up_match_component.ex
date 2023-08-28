defmodule PopUpMatchComponent do
  use Phoenix.Component
  alias Phoenix.LiveView.JS


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
          <p>
           Name: <%= parse_popup_content(assigns[:popup_content]) %>
          </p>
          <p>Phone: <%= assigns[:popup_content].phone %></p>
        </div>
        <div class="pop-col">
          <button phx-click="user_alert_match_review" value={assigns.id} title="Review user before accept">Review</button>
          <button phx-click="user_alert_match_reject" value={assigns.id} title="Reject and delete incoming response" data-confirm="This cannot be undone. Are you sure?">Reject</button>
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
  defp parse_popup_content(nil), do: nil
  defp parse_popup_content(popup_conent) when is_map(popup_conent) do
    "#{popup_conent.last_name}, #{popup_conent.first_name}"
  end
  defp parse_popup_content(popup_conent) when is_binary(popup_conent) do
    popup_conent
  end
end
