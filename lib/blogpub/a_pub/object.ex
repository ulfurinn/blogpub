defmodule Blogpub.APub.Object do
  defstruct [
    :id,
    :type,
    :name,
    :summary,
    :content,
    :url,
    :attributedTo,
    :published,
    :to,
    :cc,
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
