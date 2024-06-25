defmodule BlogpubWeb.APub.JSON do
  use BlogpubWeb, :json

  def actor(%{actor: actor}) do
    actor
  end
end
