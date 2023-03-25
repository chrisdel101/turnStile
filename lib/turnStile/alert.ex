defmodule TurnStile.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  schema "alerts" do
    field :text, :string

    timestamps()
  end

  @doc false
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:text])
    |> validate_required([:text])
  end
end
