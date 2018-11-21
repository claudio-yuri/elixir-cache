defmodule CacheTest do
  use ExUnit.Case, async: true
  doctest Cache

  test "tests empty value" do
    assert Cache.read(:nada) == nil
  end

  test "test newly written value" do
    new_value = "new_value1"
    new_key = :key1
    Cache.write(new_key, new_value)
    assert Cache.read(new_key) == new_value
  end

  test "test get_stats" do
    new_value = "new_value2"
    new_key = :key2
    Cache.write(new_key, new_value)
    stats = Cache.get_stats
    assert Map.has_key?(stats, new_key)
    assert Map.get(stats, new_key) == new_value
  end

  test "test exist?" do
    new_value = "new_value3"
    new_key = :key3
    Cache.write(new_key, new_value)
    assert Cache.exist?(new_key)
  end

  test "test delete" do
    new_value = "new_value4"
    new_key = :key4
    Cache.write(new_key, new_value)
    assert Cache.exist?(new_key)
    Cache.delete(new_key)
    refute Cache.exist?(new_key)
  end

  test "test clear" do
    new_value = "new_value5"
    new_key = :key5
    Cache.write(new_key, new_value)
    Cache.clear
    refute Cache.exist?(new_key)
    assert (Cache.get_stats |> Map.to_list |> length) == 0
  end
end
