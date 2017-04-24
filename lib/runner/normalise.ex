defmodule Harnais.Runner.Normalise do

  @moduledoc ~S"""
  Utility Functions to normalise the Test Specifications.
  """

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

  defp harnais_normalise_test_mfa_maybe_args(mfa, mod, args) do

    case mfa do
      f when is_function(f) -> {f, args}
      {nil, f, a} -> {mod |> harnais_validate_module!, f, a}
      {nil, f} -> {mod |> harnais_validate_module!, f, args}
      {m, f} -> {m, f, args}
      {m, f, a} -> {m, f, a}
    end

  end

  defp harnais_normalise_test_mfa_no_args(mfa, mod) do

    case mfa do
      f when is_function(f) -> {f, []}
      {nil, f, a} -> {mod |> harnais_validate_module!, f, a}
      {nil, f} -> {mod |> harnais_validate_module!, f, []}
      {m, f} -> {m, f, []}
      {m, f, a} -> {m, f, a}
    end

  end

  defp harnais_normalise_test_mfas_reduce_args(mfas, mod, args) do

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

  # Any fun that returns nil, short circuits the reduce pipeline

  defp test_spec_reduce_transform_funs(funs) do

    funs = funs
    |> List.wrap
    |> List.flatten
    |> Enum.reject(&is_nil/1)

    case funs |> length do

      0 -> fn test_spec, _spec, _opts -> test_spec end

      _ ->

        cond do

          # one arg i.e. just the test_spec?
          Enum.all?(funs, &(is_function(&1,1))) ->

            fn test_spec, _spec, _opts ->
              funs
              |> Enum.reduce(test_spec, fn
                _f,nil -> nil
                f,s -> f.(s)
              end)
            end

          # two args i.e. test_spec + spec?
          Enum.all?(funs, &(is_function(&1,2))) ->

            fn test_spec, spec, _opts ->
              funs
              |> Enum.reduce(test_spec, fn
                _f,nil -> nil
                f,s -> f.(s, spec)
              end)
            end

         # three args i.e. test_spec + spec + opts?
         Enum.all?(funs, &(is_function(&1,3))) ->

            fn test_spec, spec, opts ->
              funs
              |> Enum.reduce(test_spec, fn
                _f,nil -> nil
                f,s -> f.(s, spec, opts)
              end)
            end

         # must be mixed arities
         true ->

            fn test_spec, spec, opts ->
              funs
              |> Enum.reduce(test_spec, fn
                _f,nil -> nil
                f,s when is_function(f, 1) -> f.(s)
                f,s when is_function(f, 2) -> f.(s, spec)
                f,s when is_function(f, 3) -> f.(s, spec, opts)
              end)
            end

        end

    end

  end

  # These take a test_call and return the proto test_spec

  # nil => identity function
  defp normalise_test_spec_call_base(test_call) when is_nil(test_call) do
    %{
      @harnais_opts_key_test_mfas => [&(&1)],
    }
  end

  # a function of the test_module
  defp normalise_test_spec_call_base(test_call) when is_atom(test_call) do
    %{
      @harnais_opts_key_test_mfas => [{nil, test_call}],
    }
  end

  defp normalise_test_spec_call_base(test_call) when is_function(test_call) do
    %{
      @harnais_opts_key_test_mfas => [test_call],
    }
  end

  defp normalise_test_spec_call_base({m,f,a} = test_call)
  when is_atom(m) and is_atom(f) and is_list(a) do
    %{
      @harnais_opts_key_test_mfas => [test_call],
    }
  end

  defp normalise_test_spec_call_base({m,f,a} = test_call)
  when is_atom(m) and is_atom(f) and is_tuple(a) do
    %{
      @harnais_opts_key_test_mfas => [test_call],
    }
  end

  defp normalise_test_spec_call_base({test_fun, comp_fun}) do
    %{
      @harnais_opts_key_test_mfas => [{nil, test_fun}],
      @harnais_opts_key_compare_mfas => [{nil, comp_fun}]
    }
  end

  defp normalise_test_spec_call_base(test_calls) when is_list(test_calls) do

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

  defp normalise_test_spec_call(test_spec, spec) do

    fn_test_namer = spec |> spec_test_namer_get(&(&1))
    test_mod = spec |> spec_test_module_get
    comp_mod = spec |> spec_compare_module_get
    test_args = test_spec |> spec_test_args_get([])

    test_spec
    |> spec_test_call_get
    |> normalise_test_spec_call_base
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
    |> Map.merge(test_spec, fn _k, v1, _v2 -> v1 end)

  end

  @doc ~S"""
  Takes a `test specification` and converts each known key into its
  canonical name (e.g. `:v` to `:test_value`). Unknown keys are left unchanged.

  ## Examples

      iex> [c: :get, unknown_key: 99, a: [:b, 42]] |> test_spec_maybe_normalise_canon_keys
      [test_call: :get, unknown_key: 99, test_args: [:b, 42]]
  """

  def test_spec_maybe_normalise_canon_keys(test_spec)

  def test_spec_maybe_normalise_canon_keys(test_spec) when is_list(test_spec) do
    test_spec
    |> Enum.map(fn {k,v} ->
      case @harnais_test_spec_map_aliases |> Map.has_key?(k) do
        true -> {Map.fetch!(@harnais_test_spec_map_aliases, k), v}
         _ -> {k,v}
      end
    end)
  end

  def test_spec_maybe_normalise_canon_keys(test_spec) when is_map(test_spec) do

    test_spec
    |> Map.to_list
    |> test_spec_maybe_normalise_canon_keys
    |> Enum.into(%{})

  end

  defp normalise_enum_keys!(enum, keys_map) when is_map(keys_map) do
    enum
    |> Enum.map(fn {k,v} -> {Map.fetch!(keys_map, k), v} end)
  end

  @doc ~S"""
  Takes a `test specification` and tries to convert  each key into its
  canonical name (e.g. `:v` to `:test_value`).

  If all keys are known, returns `{:ok, test_spec}`, else it returns
  `{:error, {test_spec_known}, test_spec_unknown}}` with the known and
  unknown kv pairs respectively.

  ## Examples

      iex> [c: :get, a: [:b, 42]] |> test_spec_normalise_canon_keys
      {:ok, [test_call: :get, test_args: [:b, 42]]}

      iex> [unknown_key: 99, c: :get, a: [:b, 42]] |> test_spec_normalise_canon_keys
      {:error, {[test_call: :get, test_args: [:b, 42]], [unknown_key: 99]}}
  """

  def test_spec_normalise_canon_keys(test_spec)

  def test_spec_normalise_canon_keys(test_spec) do

    test_spec
    # split into known and unknown keys
    |> Enum.split_with(fn {k,_v} -> Map.has_key?(@harnais_test_spec_map_aliases, k) end)
    |> case do
         # no unknown keys
         {known_kvs, []} ->
           {:ok, known_kvs |> normalise_enum_keys!(@harnais_test_spec_map_aliases)}
        {known_kvs, unknown_kvs} ->
           {:error,
            {known_kvs |> normalise_enum_keys!(@harnais_test_spec_map_aliases),
            unknown_kvs}}

       end

  end

  @doc ~S"""
  Takes a `test specification` and converts each key into its
  canonical name (e.g. `:v` to `:test_value`). Any unknown keys will
  raise a `KeyError`.
  """

  def test_spec_normalise_canon_keys!(test_spec)

  # def test_spec_normalise_canon_keys!(test_spec) when is_list(test_spec) do
  #   test_spec
  # end

  def test_spec_normalise_canon_keys!(test_spec) when is_list(test_spec) do
    test_spec |> normalise_enum_keys!(@harnais_test_spec_map_aliases)
  end

  def test_spec_normalise_canon_keys!(test_spec) when is_map(test_spec) do
    test_spec
    |> Map.to_list
    |> test_spec_normalise_canon_keys!
    |> Enum.into(%{})
  end

  @doc false
  def test_spec_normalise_kv(kv)

  # if test_result is nil, return a fun to compare with nil
  def test_spec_normalise_kv({:test_result, nil}) do
    {:test_result, fn v -> is_nil(v) end}
  end

  # default
  def test_spec_normalise_kv(kv) do
    kv
  end

  @doc false
  def test_spec_normalise_base(test_spec)

  def test_spec_normalise_base(test_spec) do
    test_spec
    |> test_spec_normalise_canon_keys!
    |> Stream.map(&test_spec_normalise_kv/1)
    |> Enum.into(%{})
  end

  @doc false
  def test_spec_normalise_form(test_spec, spec, opts)

  def test_spec_normalise_form(test_spec, _spec, _opts) when is_list(test_spec) do

    cond do

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
    |> Enum.into(%{})

  end

  def test_spec_normalise_form(test_spec, _spec, _opts) when is_tuple(test_spec) do

    case test_spec |> tuple_size do
      5 -> [@harnais_test_spec_tuple_key_order, test_spec |> Tuple.to_list]
      # no test_value
      4 -> [@harnais_test_spec_tuple_key_order, test_spec |> Tuple.to_list]
      # no test_value and test_result
      3 -> [@harnais_test_spec_tuple_key_order, test_spec |> Tuple.to_list]
    end
    |> Enum.zip
    |> Enum.into(%{})

  end

  def test_spec_normalise_form(test_spec, _spec, _opts) when is_map(test_spec) do
    test_spec
  end

  @doc false
  def test_spec_normalise(test_spec, spec \\ %{}, opts \\ []) do

    test_spec
    |> test_spec_normalise_form(spec, opts)
    |> test_spec_normalise_base
    |> normalise_test_spec_call(spec)

  end

  @doc ~S"""
  Takes a `test specification` and converts each known key into its
  canonical name (e.g. `:v` to `:test_value`). Unknown keys are left unchanged.

  ## Examples

      iex> [v: %{a: 1}, unknown_key: 99, d: Map] |> spec_maybe_normalise_canon_keys
      [test_value: %{a: 1}, unknown_key: 99, test_module: Map]
  """

  def spec_maybe_normalise_canon_keys(spec)

  def spec_maybe_normalise_canon_keys(spec) when is_list(spec) do
    spec
    |> Enum.map(fn {k,v} ->
      case @harnais_spec_map_aliases |> Map.has_key?(k) do
        true -> {Map.fetch!(@harnais_spec_map_aliases, k), v}
        _ -> {k,v}
      end
    end)
  end

  def spec_maybe_normalise_canon_keys(spec) when is_map(spec) do
    spec
    |> Map.to_list
    |> spec_maybe_normalise_canon_keys
    |> Enum.into(%{})
  end

  @doc ~S"""
  Takes the complete runner specification and tries to convert each key into its
  canonical name (e.g. `:d` to `:module`).

  If all keys are known, returns `{:ok, spec}`, else it returns
  `{:error, {spec_known}, spec_unknown}}` with the known and
  unknown kv pairs respectively.

  ## Examples

      iex> [v: %{a: 1}, d: Map] |> spec_normalise_canon_keys
      {:ok, [test_value: %{a: 1}, test_module: Map]}

      iex> [unknown_key: 99, v: %{a: 1}, d: Map] |> spec_normalise_canon_keys
      {:error, {[test_value: %{a: 1}, test_module: Map], [unknown_key: 99]}}
  """

  def spec_normalise_canon_keys(spec)

  def spec_normalise_canon_keys(spec) do

    spec
    # split into known and unknown keys
    |> Enum.split_with(fn {k,_v} -> Map.has_key?(@harnais_spec_map_aliases, k) end)
    |> case do
         # no unknown keys
         {known_kvs, []} ->
           {:ok, known_kvs |> normalise_enum_keys!(@harnais_spec_map_aliases)}
         {known_kvs, unknown_kvs} ->
           {:error,
            {known_kvs |> normalise_enum_keys!(@harnais_spec_map_aliases),
            unknown_kvs}}
       end

  end

  @doc ~S"""
  Takes the complete runner specification and converts each key into its
  canonical name (e.g. `:d` to `:module`). Any unknown keys will
  raise a `KeyError`.
  """

  def spec_normalise_canon_keys!(spec)

  def spec_normalise_canon_keys!(spec) when is_list(spec) do
    spec
    |> Enum.map(fn {k,v} -> {Map.fetch!(@harnais_spec_map_aliases, k), v} end)
  end

  def spec_normalise_canon_keys!(spec) when is_map(spec) do
    spec
    |> Map.to_list
    |> spec_normalise_canon_keys!
    |> Enum.into(%{})
  end

  # header
  defp spec_normalise_kv(spec, kv, opts \\ [])

  defp spec_normalise_kv(spec, {:test_specs, test_specs}, opts) do

    # build a reducer fun
    fn_test_spec_reducer =
      case spec |> Map.has_key?(:test_transform) do

        # has a test_transform => complete pipeline
        true -> spec |> Map.get(:test_transform)

        _ ->

          [

          # use supplied mappers - any number of
          spec |> spec_test_mapper_get(nil),

          # normalise the test_spec
          &test_spec_normalise/3,

          ]
      end
     |> test_spec_reduce_transform_funs

    test_specs = test_specs
    |> Stream.map(fn test_spec -> fn_test_spec_reducer.(test_spec, spec, opts) end)
    # reducer fun can return nil => drop test
    |> Enum.reject(&is_nil/1)

    spec |> spec_test_specs_put(test_specs)

  end

  defp spec_normalise_kv(spec, {k, v}, _opts)
  when k in @harnais_spec_keys_all do
    fun_name = ["spec_", k, "_put"] |> Enum.join |> String.to_atom
    apply(Harnais.Accessors, fun_name, [spec, v])
  end

  @doc false

  def spec_normalise(spec)

  def spec_normalise(opts) when is_list(opts) do
    opts
    |> Enum.into(%{})
    # passthru to map
    |> spec_normalise
  end

 def spec_normalise(spec) when is_map(spec) do

    # canonical keys
    spec = spec
    |> spec_normalise_canon_keys
    |> case do
         {:ok, known_kvs} -> known_kvs
         {:error, {_known_kvs, unknown_kvs}} ->
           message = "Harnais: unknown runner opts #{inspect unknown_kvs} spec #{inspect spec}"
           Logger.error message
           raise ArgumentError, message: message
       end
    |> Enum.into(%{})

    # this list is *ordered*
    @harnais_spec_keys_all
    |> Enum.reduce(spec,
    fn k, s ->

      case s |> Map.has_key?(k) do
        true -> s |> spec_normalise_kv({k, Map.fetch!(s, k)})
        _ -> s
      end

    end)

  end

end

