defmodule Blogpub.APub.Activity do
  @derive Jason.Encoder

  defstruct [
    :id,
    :type,
    :actor,
    :object,
    "@context": "https://www.w3.org/ns/activitystreams"
  ]
end
