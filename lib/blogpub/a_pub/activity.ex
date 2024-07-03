defmodule Blogpub.APub.Activity do
  defstruct [
    :id,
    :type,
    :actor,
    :object,
    context: "https://www.w3.org/ns/activitystreams"
  ]

  defimpl Jason.Encoder do
    import Blogpub.MapExt

    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> replace(:context, "@context")
      |> Jason.Encode.map(opts)
    end
  end
end
