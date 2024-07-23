defmodule Blogpub.APub.OrderedCollectionPage do
  defstruct [
    :id,
    :totalItems,
    :next,
    :partOf,
    :prev,
    :orderedItems,
    type: "OrderedCollectionPage",
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
