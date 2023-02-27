

defmodule AdminRolesEnum do
  @roles  [:owner, :developer, :admin, :editor, :contributor, :viewer]
  def get_roles do
    @roles #access attribute
  end
end
defmodule AlertTypesEnum do
  @roles  [:initial, :confirmation, :req_for_conf, :cancellation, :change]
  def get_roles do
    @roles #access attribute
  end
end
