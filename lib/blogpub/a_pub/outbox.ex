defmodule Blogpub.APub.Outbox do
  defstruct [
    :id,
    :summary,
    :total_items,
    :ordered_items,
    context: "https://www.w3.org/ns/activitystreams",
    type: "OrderedCollection"
  ]

  defimpl Jason.Encoder do
    import Blogpub.MapExt

    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> replace(:context, "@context")
      |> replace(:total_items, "totalItems")
      |> replace(:ordered_items, "orderedItems")
      |> Jason.Encode.map(opts)
    end
  end
end
