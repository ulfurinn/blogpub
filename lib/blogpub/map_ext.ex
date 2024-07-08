defmodule Blogpub.MapExt do
  def compact(map) do
    map
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Enum.into(%{})
  end
end
