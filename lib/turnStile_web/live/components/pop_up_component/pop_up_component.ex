defmodule PopUpComponent do
  use Phoenix.Component
  alias Phoenix.LiveView.JS


  def render(assigns) do
    message_id = "message-#{assigns.id}"
    ~H"""
    <div id={message_id}class="pop-up alert alert-info">
      <div class="pop-col">
        <p>Message #<%= assigns.id %></p>
      <%= if assigns[:popup_content] do %>
        Sender: <%= assigns.popup_content %>
      <% end %>
      </div>
      <div class="pop-col">
        <button phx-click="user_registration_accept">Review</button>
        <button phx-click="user_registration_reject">Reject</button>
      </div>
      <div class="pop-col">
       <a href="#" class="phx-modal-close" phx-click={hide_popup(message_id)}>✖</a>
      </div>
    </div>
    """
  end
  def hide_popup(popup_id) do
    %JS{}
    |> JS.hide(transition: "fade-out", to: "##{popup_id}")
  end

end
