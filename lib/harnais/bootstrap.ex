defmodule Harnais.Bootstrap do
  @moduledoc false

  import ExUnit.Assertions

  def harnais_assert_is_equal(test_value, value) do
    assert test_value == value
    value
  end

  def harnais_map_convert_keys_to_list(map) when is_map(map) do
    map |> Enum.map(fn {k, v} -> {[k], v} end) |> Enum.into(%{})
  end

  def name_to_string(names) do
    names
    |> List.wrap()
    |> List.flatten()
    |> Stream.map(fn
      value when is_binary(value) -> value
      value when is_atom(value) -> value |> to_string
      value when is_nil(value) -> nil
    end)
    |> Stream.reject(&is_nil/1)
    |> Enum.join()
  end

  def name_to_atom(names) do
    names
    |> name_to_string
    |> String.to_atom()
  end

  defmacro __using__(_opts \\ []) do
    quote do
      require Harnais.Bootstrap
      import Harnais.Bootstrap
    end
  end
end
