defmodule Harnais.Accessors do

  @moduledoc false

  use Harnais.Bootstrap
  use Harnais.Attributes

  accessor_spec_default = %{funs: [:get, :fetch!, :put]}
  accessor_specs = [

    test_flag: nil,
    test_mapper: nil,
    test_runner: nil,
    test_module: nil,
    test_namer: nil,
    test_call: %{funs: [:get, :fetch!, :put, :delete]},
    test_value: %{funs: [:get, :fetch!, :put, :delete]},
    test_args: nil,
    test_result: nil,
    test_specs:  %{funs: [:get, :fetch!, :put, :delete]},
    test_mfas: nil,
    test_spec_normalise: nil,

    compare_module: nil,
    compare_mfas: nil,
  ]
  |> Enum.map(fn
    {name, spec} when is_nil(spec) -> {name, accessor_spec_default}
    x -> x
    end)

  for {name, spec} <- accessor_specs do

    spec
    |> Map.get(:funs)
    |> Enum.map(fn fun ->

      fun_name = ["spec_", name, "_", fun] |> Enum.join |> String.to_atom

      case fun do

        :get ->

          def unquote(fun_name)(state, default \\ nil) do
            Map.get(state, unquote(name), default)
          end

        :fetch! ->

          def unquote(fun_name)(state) do
            Map.fetch!(state, unquote(name))
          end

        :put ->

          def unquote(fun_name)(state, value) do
             Map.put(state, unquote(name), value)
          end

        :delete ->

          def unquote(fun_name)(state) do
            Map.delete(state, unquote(name))
          end

      end

    end)

  end

  # since spec has only one level, its a simple map merge
  def spec_merge(spec, opts, merge_fun \\ nil) do

    case merge_fun do

      fun when fun != nil ->

        Map.merge(spec, opts |> Enum.into(%{}), fun)

      _ ->

        Map.merge(spec, opts |> Enum.into(%{}))

    end

  end

end
