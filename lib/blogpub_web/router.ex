defmodule BlogpubWeb.Router do
  use BlogpubWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    # plug BlogpubWeb.ApiKeyAuth
  end

  scope "/", BlogpubWeb do
    pipe_through :api
    get "/", Home.Controller, :index

    get "/.well-known/webfinger", Webfinger.Controller, :resource
    post "/inbox", APub.Controller, :inbox

    get "/:feed", APub.Controller, :actor
    post "/:feed/inbox", APub.Controller, :inbox
    get "/:feed/outbox", APub.Controller, :outbox
    get "/:feed/following", APub.Controller, :following
    get "/:feed/followers", APub.Controller, :followers

    get "/*path", APub.Controller, :object
  end
end
