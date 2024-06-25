defmodule Blogpub.APub.PublicKey do
  defstruct [
    :id,
    :owner,
    :public_key_pem
  ]

  defimpl Jason.Encoder do
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Blogpub.MapExt.replace(:public_key_pem, "publicKeyPem")
      |> Jason.Encode.map(opts)
    end
  end
end
