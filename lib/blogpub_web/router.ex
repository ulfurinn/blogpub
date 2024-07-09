defmodule BlogpubWeb.Router do
  use BlogpubWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug BlogpubWeb.ApiKeyAuth
  end

  scope "/", BlogpubWeb do
    pipe_through :api
    get "/", Home.Controller, :index

    get "/.well-known/webfinger", Webfinger.Controller, :resource

    get "/feed/:feed", APub.Controller, :actor
    post "/feed/:feed/inbox", APub.Controller, :inbox
    get "/feed/:feed/outbox", APub.Controller, :outbox
    get "/feed/:feed/following", APub.Controller, :following
    get "/feed/:feed/followers", APub.Controller, :followers

    post "/inbox", APub.Controller, :inbox
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:blogpub, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: BlogpubWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
