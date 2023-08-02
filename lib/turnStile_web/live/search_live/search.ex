defmodule TurnStileWeb.SearchLive.Search do
  use TurnStileWeb, :live_component
  @json TurnStile.Utils.read_json("alert_text.json")

  @impl true
  def update(props, socket) do


    {:ok,
     socket
     |> assign(props)
     |> assign(:json, @json)}
  end

  @impl true
  def handle_event(action, params, socket) do
    ###
  end

  def user_search(conn, params) do
    # slugigy param
    slug = Slug.slugify(params["organization"]["name"] || "")
    # check if org name exists
    organization = Company.get_organization_by_name(slug)

    if !organization do
      conn
      |> put_flash(:error, "No organization by that name.")
      |> redirect(to: Routes.organization_path(conn, :search_get))
    else
      redirect(conn, to: Routes.organization_path(conn, :show, organization.id))
    end
  end
end
