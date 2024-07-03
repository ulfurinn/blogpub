defmodule Blogpub.APub.Image do
  @derive Jason.Encoder

  defstruct [
    :mediaType,
    :url,
    type: "Image"
  ]
end
