defmodule RaBackendWeb.Router do
  use RaBackendWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RaBackendWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RaBackendWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Users
    live "/users", GraUserLive.Index, :index
    live "/users/new", GraUserLive.Index, :new
    live "/users/:id/edit", GraUserLive.Index, :edit
    live "/users/:id", GraUserLive.Show, :show

    # Labels
    live "/labels", GraLabelLive.Index, :index
    live "/labels/new", GraLabelLive.Index, :new
    live "/labels/:id/edit", GraLabelLive.Index, :edit
    live "/labels/:id", GraLabelLive.Show, :show

    # Characters - FIX THE ROUTES
    live "/gra_characters", GraCharacterLive.Index, :index
    live "/gra_characters/new", GraCharacterLive.Index, :new
    live "/gra_characters/:id/edit", GraCharacterLive.Index, :edit
    live "/gra_characters/:id", GraCharacterLive.Show, :show

    # Character Handles (MISSING - ADD THESE)
    live "/character-handles", GraCharacterHandleLive.Index, :index
    live "/character-handles/new", GraCharacterHandleLive.Index, :new
    live "/character-handles/:id/edit", GraCharacterHandleLive.Index, :edit
    live "/character-handles/:id", GraCharacterHandleLive.Show, :show

    # Character Labels (MISSING - ADD THESE)
    live "/character-labels", GraCharacterLabelLive.Index, :index
    live "/character-labels/new", GraCharacterLabelLive.Index, :new
    live "/character-labels/:id/edit", GraCharacterLabelLive.Index, :edit
    live "/character-labels/:id", GraCharacterLabelLive.Show, :show
  end

  scope "/api", RaBackendWeb do
    pipe_through :api

    get "/labels", LabelController, :index

    # API Endpoints (MISSING - ADD THESE)
    resources "/characters", CharacterController, only: [:index, :show, :create, :update, :delete]
    resources "/character-handles", CharacterHandleController, only: [:index, :show, :create, :update, :delete]
    resources "/users", UserController, only: [:index, :show, :create, :update, :delete]
  end

  # Other scopes may use custom stacks.
  # scope "/api", RaBackendWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ra_backend, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RaBackendWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
