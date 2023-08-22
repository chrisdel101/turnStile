defmodule PopUpComponent do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <div id={assigns[:id]} class="pop_up alert alert-info">
      <%= assigns[:popup_content] %>
      <button phx-click="user_registration_accept">Review</button>
      <button phx-click="user_registration_reject">Reject</button>
    </div>
    """
  end

end
