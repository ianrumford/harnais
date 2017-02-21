defmodule Harnais.Runner.Normalise do

  @moduledoc false

  require Logger
  #import ExUnit.Assertions
  use Harnais.Attributes
  import Harnais.Accessors

  defp harnais_validate_module!(any)

  defp harnais_validate_module!(module) when is_atom(module) do
    module
  end

  defp harnais_validate_module!(value) do
    message = "test_module is not a atom #{inspect value}"
    Logger.error message
    raise ArgumentError, message: message
  end

  def harnais_normalise_test_mfa_always_args(mfa, mod, args) do

    case mfa do
      {nil, f, a} -> {mod |> harnais_validate_module!, f, List.wrap(args) ++ a}
      {nil, f} -> {mod |> harnais_validate_module!, f, args}
      {m, f} -> {m, f, args}
      {m, f, a} -> {m, f, List.wrap(args) ++ a}
    end

  end

  def harnais_normalise_test_mfa_maybe_args(mfa, mod, args) do

    case mfa do
      f when is_function(f) -> {f, args}
      {nil, f, a} -> {mod |> harnais_validate_module!, f, a}
      {nil, f} -> {mod |> harnais_validate_module!, f, args}
      {m, f} -> {m, f, args}
      {m, f, a} -> {m, f, a}
    end

  end

  def harnais_normalise_test_mfa_no_args(mfa, mod) do

    case mfa do
      f when is_function(f) -> {f, []}
      {nil, f, a} -> {mod |> harnais_validate_module!, f, a}
      {nil, f} -> {mod |> harnais_validate_module!, f, []}
      {m, f} -> {m, f, []}
      {m, f, a} -> {m, f, a}
    end

  end

  def harnais_normalise_test_mfas_reduce_args(mfas, mod, args \\ []) do

    mfas
    |> Enum.with_index
    |> Enum.map(
    fn
      # if the mfa already has args, don't add anymore
      {mfa, 0} -> mfa |> harnais_normalise_test_mfa_maybe_args(mod, args)
      # 2nd and subsequent mfas must have args
      {mfa, _} -> mfa |> harnais_normalise_test_mfa_no_args(mod)
    end)

  end

  # These take a test_call and return the proto test_spec

  # nil => identity function
  defp spec_normalise_test_call_base(test_call) when is_nil(test_call) do
    %{
      @harnais_opts_key_test_mfas => [&(&1)],
    }
  end

  # a function of the test_module
  defp spec_normalise_test_call_base(test_call) when is_atom(test_call) do
    %{
      @harnais_opts_key_test_mfas => [{nil, test_call}],
    }
  end

  defp spec_normalise_test_call_base(test_call) when is_function(test_call) do
    %{
      @harnais_opts_key_test_mfas => [test_call],
    }
  end

  defp spec_normalise_test_call_base({m,f,a} = test_call)
  when is_atom(m) and is_atom(f) and is_list(a) do
    %{
      @harnais_opts_key_test_mfas => [test_call],
    }
  end

  defp spec_normalise_test_call_base({m,f,a} = test_call)
  when is_atom(m) and is_atom(f) and is_tuple(a) do
    %{
      @harnais_opts_key_test_mfas => [test_call],
    }
  end

  defp spec_normalise_test_call_base({test_fun, comp_fun}) do
    %{
      @harnais_opts_key_test_mfas => [{nil, test_fun}],
      @harnais_opts_key_compare_mfas => [{nil, comp_fun}]
    }
  end

  defp spec_normalise_test_call_base(test_calls) when is_list(test_calls) do

    test_mfas = test_calls
    |> Enum.map(
    fn

      test_call when is_atom(test_call) -> {nil, test_call}
      test_call when is_function(test_call) -> test_call
      {m, f} -> {m, f}
      {m, f, a} -> {m, f, a}

    end)

    test_spec = %{
      @harnais_opts_key_test_mfas => test_mfas,
    }

    test_spec

  end

  defp spec_normalise_test_call(spec, test_call, opts) do

    spec = opts |> Enum.into(spec)

    fn_test_namer = spec |> spec_test_namer_get(&(&1))
    test_mod = spec |> spec_test_module_get
    comp_mod = spec |> spec_compare_module_get
    test_args = spec |> spec_test_args_get([])

    test_call
    |> spec_normalise_test_call_base
    |> fn

      %{@harnais_opts_key_test_mfas => test_mfas} = test_call ->

        test_mfas = test_mfas
        |> harnais_normalise_test_mfas_reduce_args(test_mod, test_args)
        # apply the src fun namer
        |> Enum.map(fn
          {f, a} when is_function(f) -> {f, a}
          {m, f, a} -> {m, f |> fn_test_namer.(), a}
          {m, f} -> {m, f |> fn_test_namer.()}
        end)

        test_call |> Map.put(@harnais_opts_key_test_mfas, test_mfas)

      # passthru
      test_call -> test_call
    end.()
    |> fn
      %{@harnais_opts_key_compare_mfas => comp_mfas} = test_call ->

        comp_mfas = comp_mfas
        |> harnais_normalise_test_mfas_reduce_args(comp_mod, test_args)

      test_call |> Map.put(@harnais_opts_key_compare_mfas, comp_mfas)

      test_call -> test_call

    end.()
    |> Map.merge(spec, fn _k, v1, _v2 -> v1 end)

  end

  defp spec_normalise_call_spec(spec, call_opts, opts) do

    call_spec = call_opts
    |> normalise_test_spec_keys
    |> Enum.into(%{})

    test_call = call_spec |> spec_test_call_get

    test_call_opts = opts
    |> normalise_test_spec_keys
    |> Enum.into(%{})
    |> spec_merge(call_spec)
    |> spec_test_call_delete

    spec
    # housekeeping
    |> spec_test_specs_delete
    # don't make the test_value available
    |> spec_test_value_delete
    |> spec_normalise_test_call(test_call, test_call_opts)

  end

  def normalise_test_spec_kv(kv)

  # if test_result is nil, retruna fun to compare with nil
  def normalise_test_spec_kv({:test_result, nil}) do
    {:test_result, fn v -> is_nil(v) end}
  end

  # default
  def normalise_test_spec_kv(kv) do
    kv
  end

  defp normalise_test_spec_keys(test_spec)

  defp normalise_test_spec_keys(test_spec) when is_list(test_spec) do

    test_spec
    |> Enum.map(fn {k,v} ->
      {Map.fetch!(@harnais_test_spec_key_alias_to_canon, k), v}
      |> normalise_test_spec_kv
    end)

  end

  defp normalise_test_spec_keys(test_spec) when is_map(test_spec) do

    test_spec
    |> Map.to_list
    |> normalise_test_spec_keys
    |> Enum.into(%{})

  end

  defp spec_normalise_test_spec(spec, test_spec, opts)

  defp spec_normalise_test_spec(spec, test_spec, opts) when is_list(test_spec) do

    test_call_opts = cond do

      Keyword.keyword?(test_spec) -> test_spec

      true ->

        case test_spec |> length do
          5 -> [@harnais_test_spec_tuple_key_order, test_spec]
          # no test_value
          4 -> [@harnais_test_spec_tuple_key_order, test_spec]
          # no test_value and test_result
          3 -> [@harnais_test_spec_tuple_key_order, test_spec]
        end
       |> Enum.zip

    end

    spec
    |> spec_normalise_call_spec(test_call_opts, opts)

  end

  defp spec_normalise_test_spec(spec, test_spec, opts) when is_tuple(test_spec) do

    test_call_opts =
      case test_spec |> tuple_size do
        5 -> [@harnais_test_spec_tuple_key_order, test_spec |> Tuple.to_list]
        # no test_value
        4 -> [@harnais_test_spec_tuple_key_order, test_spec |> Tuple.to_list]
        # no test_value and test_result
        3 -> [@harnais_test_spec_tuple_key_order, test_spec |> Tuple.to_list]
      end
    |> Enum.zip

    spec
    |> spec_normalise_call_spec(test_call_opts, opts)

  end

  defp spec_normalise_test_spec(spec, test_spec, opts) when is_map(test_spec) do

    spec
    |> spec_normalise_call_spec(test_spec, opts)

  end

  # header
  defp spec_normalise_kv(spec, kv, opts \\ [])

  defp spec_normalise_kv(spec, {:test_specs, test_specs}, opts) do

    # any mapper to do initial transform?
    # cope with arity 1 & 2 (i.e. with the spec as well)
    fn_mapper_test_spec =
      case spec |> spec_test_mapper_get(nil) do
        fun when is_nil(fun) -> &(&1)
        fun when is_function(fun, 1) ->
          fn test_specs -> test_specs |> Enum.map(fun) end
        fun when is_function(fun, 2) ->
          fn test_specs ->
            test_specs
            |> Enum.map(fn test_spec -> fun.(test_spec, spec) end)
          end
      end

    fn_normalise_test_spec = spec |> spec_test_spec_normalise_get(&spec_normalise_test_spec/3)

    test_specs = test_specs
    |> fn_mapper_test_spec.()
    |> Enum.map(fn test_spec -> fn_normalise_test_spec.(spec, test_spec, opts) end)

    spec |> spec_test_specs_put(test_specs)

  end

  defp spec_normalise_kv(spec, {:test_mapper, _test_mapper}, _opts) do

    test_mappers = spec
    |> spec_test_mapper_get(nil)
    |> List.wrap
    |> List.flatten
    |> Enum.reject(&is_nil/1)

    test_mapper =
      case test_mappers |> length do

        0 -> nil
        1 -> test_mappers |> List.first
        _ ->

          cond do

            # one arg i.e. test_spec?
            Enum.all?(test_mappers, &(is_function(&1,1))) ->

              fn test_spec ->
                test_mappers |> Enum.reduce(test_spec, fn f,s -> f.(s) end)
              end

            # two args i.e. test_spec + spec?
            Enum.all?(test_mappers, &(is_function(&1,2))) ->

              fn test_spec, spec ->
                test_mappers |> Enum.reduce(test_spec, fn f,s -> f.(s, spec) end)
              end

           # must be mixed arities
           true ->

              fn test_spec, spec ->
                test_mappers
                |> Enum.reduce(test_spec,
                fn
                  f,s when is_function(f, 1) -> f.(s)
                  f,s when is_function(f, 2) -> f.(s, spec)
                end)
              end

          end

      end

    spec |> spec_test_mapper_put(test_mapper)

  end

  defp spec_normalise_kv(spec, {k, v}, _opts)
  when k in @harnais_opts_keys_all do
    fun_name = ["spec_", k, "_put"] |> Enum.join |> String.to_atom
    apply(Harnais.Accessors, fun_name, [spec, v])
  end

  def spec_normalise(spec)

  def spec_normalise(opts) when is_list(opts) do
    opts
    |> Enum.into(%{})
    # passthru to map
    |> spec_normalise
  end

  def spec_normalise(spec) when is_map(spec) do

    # canonical keys
    spec = spec |> normalise_test_spec_keys

    # all keys valid?
    spec
    |> Map.keys
    |> Kernel.--(@harnais_opts_keys_all)
    |> case do

         [] -> nil
         unknown_keys ->

           message = "Harnais: unknown keys #{inspect unknown_keys} spec #{inspect spec}"
           Logger.error message
           raise ArgumentError, message: message

       end

    # this list is *ordered*
    @harnais_opts_keys_all
    |> Enum.reduce(spec,
    fn k, s ->

      case s |> Map.has_key?(k) do
        true -> s |> spec_normalise_kv({k, Map.fetch!(s, k)})
        _ -> s
      end

    end)

  end

end

