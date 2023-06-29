defmodule AddUserPartialComponet do
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form, only: [label: 2, text_input: 2, number_input: 2]
  import TurnStileWeb.ErrorHelpers, only: [error_tag: 2]

  def render(assigns) do
    f = assigns.f
    ~H"""
    <h2>Add New User</h2>
    <%= label f, :first_name %>
    <%= text_input f, :first_name %>
    <%= error_tag f, :first_name %>

    <%= label f, :last_name %>
    <%= text_input f, :last_name %>
    <%= error_tag f, :last_name %>

    <%= label f, :email %>
    <%= text_input f, :email %>
    <%= error_tag f, :email %>

    <%= label f, :phone %>
    <%= text_input f, :phone %>
    <%= error_tag f, :phone %>

    <%= label f, :health_card_num %>
    <%= number_input f, :health_card_num %>
    <%= error_tag f, :health_card_num %>
    """
  end
end
