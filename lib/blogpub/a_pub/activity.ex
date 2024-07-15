defmodule Blogpub.APub.Activity do
  alias __MODULE__

  defstruct [
    :id,
    :type,
    :actor,
    :object,
    "@context": "https://www.w3.org/ns/activitystreams"
  ]

  def embedded(activity = %{"@context" => _}), do: Map.delete(activity, "@context")
  def embedded(activity = %Activity{}), do: %Activity{activity | "@context": nil}

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
