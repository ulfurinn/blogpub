defmodule Blogpub.APub.PublicKey do
  @derive Jason.Encoder
  defstruct [
    :id,
    :owner,
    :publicKeyPem
  ]
end
