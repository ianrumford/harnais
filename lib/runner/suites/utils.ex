defmodule Harnais.Runner.Tests.Utils do

  @moduledoc false

  def tests_get(dict, name, default \\ nil) do
    dict |> Map.get(name, default)
  end

  def tests_transform(dict, name, opts \\ []) do

    tests = dict |> tests_get(name)

    case opts |> Keyword.has_key?(:transform) do

      true ->

        funs = opts
        |> Keyword.get(:transform)
        |> List.wrap
        |> List.flatten
        |> Enum.reject(&is_nil/1)

        tests
        |> Enum.map(fn test ->
          funs |> Enum.reduce(test, fn f,s -> f.(s) end)
        end)

        _ -> tests

    end

  end

end
