defmodule Harnais.Runner.Suites.Map.Helpers do

  @moduledoc false

  def runner_tests_map_result(actual, test_spec) do

    expect = test_spec.test_value
    |> Harnais.Runner.Run.run_test_mfas(test_spec.test_mfas)

    expect == actual

  end

  def runner_tests_map_new_old_tuple(v) do
    {v, :new_value}
  end

  def runner_tests_map_value() do
    42
  end

  def runner_tests_map_passthru(v) do
    v
  end

end

defmodule Harnais.Runner.Suites.Map do

  @moduledoc false

  require Harnais.Runner.Suites.Map.Helpers, as: HRTMH

  @harnais_runner_tests_state_deep Harnais.Utils.Maps.harnais_new_state_deep

  @harnais_runner_tests_map %{

    default:  [

      [:r, :delete, [:a]],
      [:r, :delete, [:x]],
      [:r, :drop, [[:a, :b, :c]]],
      [:r, :drop, [[:a, :x]]],
      [:r, :equal?, [@harnais_runner_tests_state_deep]],
      [:r, :equal?, [%{}]],

      [:r, :fetch, [:a]],
      [:r, :fetch, [:x]],

      [:r, :fetch!, [:a]],
      [{:e, KeyError}, :fetch!, [:x]],

      ### from_struct

      [:r, :get, [:a]],
      [:r, :get, [:x]],

      [:r, :get_and_update, [:a, &HRTMH.runner_tests_map_new_old_tuple/1]],
      [:r, :get_and_update, [:x, &HRTMH.runner_tests_map_new_old_tuple/1]],

      [:r, :get_and_update!, [:a, &HRTMH.runner_tests_map_new_old_tuple/1]],
      [{:e, KeyError}, :get_and_update!, [:x, &HRTMH.runner_tests_map_new_old_tuple/1]],

      [:r, :get_lazy, [:a, &HRTMH.runner_tests_map_value/0]],
      [:r, :get_lazy, [:x, &HRTMH.runner_tests_map_value/0]],

      [:r, :has_key?, [:a]],
      [:r, :has_key?, [:x]],

      [:r, :keys],

      [:r, :merge, [%{a: 1, b: 2}]],

      [:r, :new],
      # is_tuple(args) => ignore test_value
      [:r, :new, [&HRTMH.runner_tests_map_passthru/1]],

      [:r, :pop, [:a]],
      [:r, :pop, [:a, 42]],
      [:r, :pop, [:x]],
      [:r, :pop, [:x, 42]],

      [:r, :pop_lazy, [:a, &HRTMH.runner_tests_map_value/0]],

      [:r, :put, [:a, 42]],
      [:r, :put, [:x, 42]],

      [:r, :put_new, [:a, 42]],
      [:r, :put_new, [:x, 42]],

      [:r, :put_new_lazy, [:a, &HRTMH.runner_tests_map_value/0]],
      [:r, :put_new_lazy, [:x, &HRTMH.runner_tests_map_value/0]],

      [:r, :split, [[:a]]],
      [:r, :split, [[:a, :x]]],

      [:r, :take, [[:a, :c]]],
      [:r, :take, [[:a, :x]]],

      [:r, :to_list],

      [:r, :update, [:a, 42, &HRTMH.runner_tests_map_passthru/1]],
      [:r, :update, [:x, 42, &HRTMH.runner_tests_map_passthru/1]],

      [:r, :update!, [:a, &HRTMH.runner_tests_map_passthru/1]],
      [{:e, KeyError}, :update!, [:x, &HRTMH.runner_tests_map_passthru/1]],

      [:r, :values],

    ]
    |> Stream.map(fn
      [flag, call] -> [f: flag, c: call, a: [], v: @harnais_runner_tests_state_deep, r: &HRTMH.runner_tests_map_result/2]
      [flag, call, args] -> [f: flag, c: call, a: args, v: @harnais_runner_tests_state_deep, r: &HRTMH.runner_tests_map_result/2]
      [flag, call, args, value] -> [f: flag, c: call, a: args, v: value, r: &HRTMH.runner_tests_map_result/2]
      [flag, call, args, value, result] -> [f: flag, c: call, a: args, v: value, r: result]
    end)
   |> Enum.map(fn test -> test |> Enum.into(%{}) end)

  }

  @args_vars 0 .. 5 |> Enum.map(fn n -> "arg#{n}" |> String.to_atom |> Macro.var(nil) end)

  @wrappers [
    tests_get: 1,
    tests_get: 2]

  for {name, arity} <- @wrappers do

    args = @args_vars |> Enum.take(arity)

    def unquote(name)(unquote_splicing(args)) do
      Harnais.Runner.Tests.Utils.unquote(name)(@harnais_runner_tests_map, unquote_splicing(args))
    end

  end

end
