defmodule BlogpubWeb.Webfinger.JSON do
  use BlogpubWeb, :json

  def resource(%{resource: resource}) do
    resource
  end
end
