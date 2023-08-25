defmodule TurnStileWeb.Router do
  use TurnStileWeb, :router

  import TurnStileWeb.AdminAuth

  import TurnStileWeb.EmployeeAuth
  import TurnStileWeb.UserAuth
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TurnStileWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_employee
    plug :fetch_current_admin
    plug :fetch_current_user
    plug :require_non_expired_user_session
    # used in template
    plug TurnStileWeb.Plugs.RouteType, "non-admin"
    plug TurnStileWeb.Plugs.EmptyParams

  end

  pipeline :api do
    plug :accepts, ["json"]

    post "/sms_messages", TurnStileWeb.AlertController, :receive_sms_alert
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only employees to access it.
  # If your application does not have an employees-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TurnStileWeb.Telemetry
    end
  end

  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  if Mix.env() == :test do
  scope "/test" do
    pipe_through :browser

    post "/organizations/:id/employees/register",
         TurnStileWeb.TestController,
         :quick_register_employee

    # get "/", TurnStileWeb.TestController, :employee_register
    get "/organizations/:id/employees/register",
        TurnStileWeb.TestController,
        :employee_register_page
    end

  end

  scope "/", TurnStileWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  if (Mix.env() == :test ||  Mix.env()) == :dev do

      scope "/", TurnStileWeb do
        pipe_through :browser

        get "/clear_sessions", FunctionsController, :clear_sessions
        get "/get_sessions", FunctionsController, :get_sessions
        get "/set_cookie", FunctionsController, :set_cookie
        get "/get_cookies", FunctionsController, :get_cookies
        get "/delete_cookie", FunctionsController, :delete_cookie
      end

  end

  ## Authentication routes

  scope "/organizations/:id", TurnStileWeb do
    pipe_through [:browser, :redirect_if_employee_is_authenticated]

    get "/employees/log_in", EmployeeSessionController, :new
    post "/employees/log_in", EmployeeSessionController, :create
    get "/employees/reset_password", EmployeeResetPasswordController, :new
    post "/employees/reset_password", EmployeeResetPasswordController, :create
    get "/employees/reset_password/:token", EmployeeResetPasswordController, :edit
    put "/employees/reset_password/:token", EmployeeResetPasswordController, :update
  end

  scope "/organizations/:id", TurnStileWeb do
    pipe_through [:browser, :require_authenticated_employee]

    get "/employees/settings", EmployeeSettingsController, :edit
    put "/employees/settings", EmployeeSettingsController, :update
    get "/employees/settings/confirm_email/:token", EmployeeSettingsController, :confirm_email

  end

  scope "/organizations/:id", TurnStileWeb do
    pipe_through [
      :browser,
      :require_register_access_employee
    ]

    get "/employees/register", EmployeeRegistrationController, :new
    post "/employees/register", EmployeeRegistrationController, :create
  end

  scope "/organizations/:id", TurnStileWeb do
    pipe_through [:browser]
    delete "/employees/log_out", EmployeeSessionController, :delete
    get "/employees/setup/:token", EmployeeConfirmationController, :setup #after employee creared, email URL directs them here viareply email link
    post "/employees/confirm/:token", EmployeeConfirmationController, :update
    put "/employees/confirm/:token", EmployeeConfirmationController, :update
  end

  scope "/", TurnStileWeb do
    pipe_through [:browser, :require_authenticated_employee]

    resources "/organizations", OrganizationController, except: [:show, :index, :new, :create] do
      # show, delete - TODO extract these since no point to nest
      resources "/employees", EmployeeController, except: [:new, :edit, :update, :index, :show]
    end

    live "/organizations/:organization_id/employees/:employee_id/users/", UserLive.Index, :index

    live "/organizations/:organization_id/employees/:employee_id/users/new", UserLive.Index, :new

    live "/organizations/:organization_id/employees/:employee_id/users/insert", UserLive.Index, :insert

    live "/organizations/:organization_id/employees/:employee_id/users/select", UserLive.Index, :select

    live "/organizations/:organization_id/employees/:employee_id/users/search", UserLive.Index, :search

    live "/organizations/:organization_id/employees/:employee_id/users/display_existing_users", UserLive.Index, :display_existing_users

    live "/organizations/:organization_id/employees/:employee_id/users/:id",
      UserLive.Show,
      :show

      live "/organizations/:organization_id/employees/:employee_id/users/:id/edit_show",
      UserLive.Show,
      :edit

      live "/organizations/:organization_id/employees/:employee_id/users/:id/alert",
        UserLive.Index,
        :alert, as: :organization_employee_user_alert


  end

  # user only in dev for testing - to quick submit a pubsub to index
  if Mix.env() in [:dev, :test] do
      # user filling out registation via self form
    scope "/organizations/:id/users/register/quick-test", TurnStileWeb do
      pipe_through [:browser, :redirect_if_user_is_authenticated]
      # check token; render form
      get "/:token", UserRegistrationController, :quick_new
      # user self form submit
      post "/:token",
      UserRegistrationController, :quick_send
    end
  end
  # user filling out registation via self form
  scope "/organizations/:id/users/register/", TurnStileWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]
    # check token; render form
    get "/:token", UserRegistrationController, :new
    # user self form submit
    post "/:token",
    UserRegistrationController, :handle_create
  end

  scope "/organizations/:organization_id/users", TurnStileWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]
    # user clicks link in email
    # first validate token is linked to user
    # second check organization matches the URL
    # third user login and redirect to :new
    get "/:user_id/:token", UserAuth, :handle_validate_email_token
  end

  scope "organizations/:organization_id/users", TurnStileWeb do
    pipe_through [:browser, :require_authenticated_user,
    :ensure_organization_matches_current_user,
    :ensure_user_id_param_matches_current_user
  ]
    # redirect here after prev :ok
    get "/:user_id", UserSessionController, :new
    # when logout button is clicked
    delete "/:user_id/log_out", UserSessionController, :delete
    # sends conf/cancel buttons request on page
    post "/:user_id", UserConfirmationController, :update

  end

  # employee edit and update req write access
  scope "/organizations/:organization_id/employees/:id", TurnStileWeb do
    pipe_through [:browser,
    :require_authenticated_employee, :require_edit_access_employee]

    get "/edit", EmployeeController, :edit
    put "/edit", EmployeeController, :update
  end

  # /employees AUTHENCIATED
  scope "/organizations/:organization_id/", TurnStileWeb do
    pipe_through [
      :browser,
      :require_authenticated_employee,
      :require_edit_access_employee
    ]
  # employee edit action - req e access
    get "/employees", EmployeeController, :index, as: :organization_employee
  end

  scope "/organizations/:organization_id/employees/:id", TurnStileWeb do
    pipe_through [
      :browser,
      :require_authenticated_employee,
      :require_is_admin_employee
    ]
  # show to employee admin and up only
    get "/", EmployeeController, :show, as: :organization_employee

    get "/employees/confirm", EmployeeConfirmationController, :new
  end

  # /organizations NON_AUTHENCIATED
  scope "/organizations", TurnStileWeb do
    pipe_through :browser

    get "/search", OrganizationController, :search_get
    post "/search", OrganizationController, :search_post

    get "/new", OrganizationController, :new
    post "/new", OrganizationController, :handle_new
    post "/", OrganizationController, :create

    get "/:id", OrganizationController, :show
  end

  ## Admin routes

  scope "/organizations", TurnStileWeb do
    pipe_through [:browser, :require_authenticated_admin]
    # only admins can see all organizations
    get "/", OrganizationController, :index
  end

  scope "/", TurnStileWeb do
    pipe_through [:browser, :redirect_if_admin_is_authenticated]

    get "/admin/register", AdminRegistrationController, :new
    post "/admin/register", AdminRegistrationController, :create
    get "/admin/log_in", AdminSessionController, :new
    post "/admin/log_in", AdminSessionController, :create
    get "/admin/reset_password", AdminResetPasswordController, :new
    post "/admin/reset_password", AdminResetPasswordController, :create
    get "/admin/reset_password/:token", AdminResetPasswordController, :edit
    put "/admin/reset_password/:token", AdminResetPasswordController, :update
  end

  scope "/admin", TurnStileWeb do
    pipe_through :browser

    delete "/log_out", AdminSessionController, :delete
    get "/confirm", AdminConfirmationController, :new
    post "/confirm", AdminConfirmationController, :create
    get "/confirm/:token", AdminConfirmationController, :edit
    post "/confirm/:token", AdminConfirmationController, :update
  end

  scope "/admin", TurnStileWeb do
    pipe_through [:browser, :require_authenticated_admin]

    get "/settings", AdminSettingsController, :edit
    put "/settings", AdminSettingsController, :update
    get "/settings/confirm_email/:token", AdminSettingsController, :confirm_email

    resources "/admins", AdminController, except: [:new]
    get "/", AdminController, :home
  end
end
