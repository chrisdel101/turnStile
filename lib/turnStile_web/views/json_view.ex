defmodule TurnStileWeb.JsonView do
  use TurnStileWeb, :view

  def render("triage.json", %{data: data}) do
    %{data: data}
  end

end
