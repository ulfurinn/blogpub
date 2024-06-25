defmodule Blogpub.MapExt do
  def replace(map, key, new_key) do
    {v, m} = Map.pop(map, key)
    Map.put(m, new_key, v)
  end
end
