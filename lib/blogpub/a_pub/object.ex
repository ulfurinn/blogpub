defmodule Blogpub.APub.Object do
  defstruct [
    :id,
    :type,
    :name,
    :summary,
    :content,
    :url,
    :attributed_to,
    :published,
    :to
  ]

  defimpl Jason.Encoder do
    import Blogpub.MapExt

    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> replace(:attributed_to, "attributedTo")
      |> delete_nil(:summary)
      |> delete_nil(:content)
      |> delete_nil(:url)
      |> Jason.Encode.map(opts)
    end
  end
end
