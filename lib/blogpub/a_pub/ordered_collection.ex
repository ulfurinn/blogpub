defmodule Blogpub.APub.OrderedCollection do
  defstruct [
    :id,
    :totalItems,
    :first,
    :items,
    :orderedItems,
    type: "OrderedCollection",
    "@context": "https://www.w3.org/ns/activitystreams"
  ]

  defimpl Jason.Encoder do
    import Blogpub.MapExt

    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> compact()
      |> Jason.Encode.map(opts)
    end
  end
end
