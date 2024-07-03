defmodule Blogpub.MapExt do
  def replace(map, key, new_key) do
    {v, m} = Map.pop(map, key)
    Map.put(m, new_key, v)
  end

  def delete_nil(map, key) do
    case Map.fetch(map, key) do
      {:ok, nil} -> Map.delete(map, key)
      {:ok, _} -> map
      :error -> map
    end
  end
end
