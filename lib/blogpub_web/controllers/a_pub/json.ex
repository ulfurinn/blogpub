defmodule BlogpubWeb.APub.JSON do
  use BlogpubWeb, :json

  def actor(%{actor: actor}) do
    actor
  end

  def outbox(%{outbox: outbox}) do
    outbox
  end
end
