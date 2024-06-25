defmodule Blogpub.APub.Actor do
  defstruct [
    :id,
    :preferred_username,
    :inbox,
    :outbox,
    :public_key,
    context: [
      "https://www.w3.org/ns/activitystreams",
      "https://w3id.org/security/v1"
    ],
    type: "Person"
  ]

  defimpl Jason.Encoder do
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Blogpub.MapExt.replace(:context, "@context")
      |> Blogpub.MapExt.replace(:preferred_username, "preferredUsername")
      |> Blogpub.MapExt.replace(:public_key, "publicKey")
      |> Jason.Encode.map(opts)
    end
  end
end
