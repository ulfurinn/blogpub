defmodule Blogpub.APub.Outbox do
  @derive Jason.Encoder
  defstruct [
    :id,
    :summary,
    :totalItems,
    :orderedItems,
    "@context": "https://www.w3.org/ns/activitystreams",
    type: "OrderedCollection"
  ]
end
