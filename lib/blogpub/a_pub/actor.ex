defmodule Blogpub.APub.Actor do
  defstruct [
    :id,
    :preferredUsername,
    :name,
    :summary,
    :url,
    :inbox,
    :outbox,
    :followers,
    :publicKey,
    :icon,
    "@context": [
      "https://www.w3.org/ns/activitystreams",
      "https://w3id.org/security/v1"
    ],
    type: "Person",
    endpoints: %{}
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
