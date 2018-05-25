defmodule Harnais.Utility do
  @moduledoc ~S"""
  Miscellaneous Utility Functions
  """

  use Harnais.Bootstrap
  use Harnais.Attribute

  @type ast :: Harnais.ast()
  @type key :: Harnais.key()
  @type keys :: Harnais.keys()
  @type opts :: Harnais.opts()
  @type error :: Harnais.error()
  @type form :: Harnais.form()
  @type forms :: Harnais.forms()

  @type alias_key :: atom
  @type alias_keys :: alias_key | [alias_key]
  @type alias_value :: nil | alias_keys

  @type alias_kvs :: [{alias_key, alias_value}]

  @type alias_tuples :: [{alias_key, alias_key}]
  @type alias_dict :: %{optional(alias_key) => alias_key}

  def new_error_result(opts \\ [])

  def new_error_result(message) when is_binary(message) do
    {:ok, %ArgumentError{message: message}}
  end

  def new_error_result(opts) do
    cond do
      Keyword.keyword?(opts) ->
        message =
          [:m, :v]
          |> Stream.map(fn k -> {k, opts |> Keyword.get(k)} end)
          |> Stream.map(fn
            {_, v} when is_nil(v) ->
              nil

            {:m, v} when is_binary(v) ->
              v

            {:v, v} ->
              "got: #{inspect(v)}"

            kv ->
              raise ArgumentError, message: "new_error_result kv invalid, got: #{inspect(kv)}"
          end)
          |> Stream.reject(&is_nil/1)
          |> Enum.join(", ")

        {:error, %ArgumentError{message: message}}

      true ->
        raise ArgumentError, message: "new_error_result opts invalid, got: #{inspect(opts)}"
    end
  end

  def new_key_error(values, term) do
    cond do
      Keyword.keyword?(values) -> values |> Keyword.keys()
      is_list(values) -> values
      true -> [values]
    end
    |> Enum.uniq()
    |> case do
      [key] -> %KeyError{key: key, term: term}
      keys -> %KeyError{key: keys, term: term}
    end
  end

  @doc false
  def new_key_error_result(values, term) do
    {:error, new_key_error(values, term)}
  end

  @doc false
  def list_wrap_flat_just(value) do
    value
    |> List.wrap()
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  @doc false
  def list_wrap_flat_just_uniq(value) do
    value
    |> List.wrap()
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  @doc false

  def string_empty?(str) when is_binary(str) do
    String.length(str) == 0
  end

  @doc false

  @since "0.1.0"

  @spec validate_key(any) :: {:ok, key} | {:error, error}

  def validate_key(key)

  def validate_key(key) when is_atom(key) do
    {:ok, key}
  end

  def validate_key(key) do
    new_error_result(m: "key invalid", v: key)
  end

  @doc false

  @since "0.1.0"

  @spec validate_keys(any) :: {:ok, keys} | {:error, error}

  def validate_keys(keys)

  def validate_keys(keys) when is_list(keys) do
    keys
    |> Enum.reject(&is_atom/1)
    |> case do
      [] ->
        {:ok, keys}

      not_atoms ->
        new_error_result(m: "keys invalid", v: not_atoms)
    end
  end

  def validate_keys(keys) do
    new_error_result(m: "keys invalid", v: keys)
  end

  @doc false

  @since "0.1.0"

  @spec normalise_keys(any) :: {:ok, keys} | {:error, error}

  def normalise_keys(keys) do
    keys
    |> list_wrap_flat_just
    |> validate_keys
  end

  @doc ~S"""
  `opts_validate/1` returns `{:ok, opts}` if the argument is an *opts*.

  Any other argument causes `{:error, error}` to be returned.

  ## Examples

      iex> [] |> opts_validate
      {:ok, []}

      iex> {:error, error} = %{a: 1, b: 2, c: 3} |> opts_validate
      ...> error |> Exception.message
      "opts invalid, got: %{a: 1, b: 2, c: 3}"

      iex> {:error, error} = %{"a" => 1, :b => 2, :c => 3} |> opts_validate
      ...> error |> Exception.message
      "opts invalid, got: %{:b => 2, :c => 3, \"a\" => 1}"

      iex> {:error, error} = 42 |> opts_validate
      ...> error |> Exception.message
      "opts invalid, got: 42"

      iex> [a: nil, b: [:b1], c: [:c1, :c2, :c3]] |> opts_validate
      {:ok, [a: nil, b: [:b1], c: [:c1, :c2, :c3]]}

  """

  @spec opts_validate(any) :: {:ok, opts} | {:error, error}

  def opts_validate(value) do
    case Keyword.keyword?(value) do
      true -> {:ok, value}
      _ -> new_error_result(m: "opts invalid", v: value)
    end
  end

  @doc ~S"""
  `opts_normalise/` expects a *derivable opts* and returns `{:ok, opts}`.

  Any other argument causes `{:error, error}` to be returned.

  ## Examples

      iex> [] |> opts_normalise
      {:ok, []}

      iex> %{a: 1, b: 2, c: 3} |> opts_normalise
      {:ok, [a: 1, b: 2, c: 3]}

      iex> %{"a" => 1, :b => 2, :c => 3} |> opts_normalise
      {:error, %KeyError{key: "a", term: %{:b => 2, :c => 3, "a" => 1}}}

      iex> {:error, error} = 42 |> opts_normalise
      ...> error |> Exception.message
      "opts not derivable, got: 42"

      iex> [a: nil, b: [:b1], c: [:c1, :c2, :c3]] |> opts_normalise
      {:ok, [a: nil, b: [:b1], c: [:c1, :c2, :c3]]}

  """

  @spec opts_normalise(any) :: {:ok, opts} | {:error, error}

  def opts_normalise(value) do
    cond do
      Keyword.keyword?(value) ->
        {:ok, value}

      is_map(value) ->
        value
        |> Enum.split_with(fn {k, _v} -> k |> is_atom end)
        |> case do
          {valid_tuples, []} ->
            {:ok, valid_tuples}

          {_valid_tuples, invalid_tuples} ->
            case invalid_tuples |> length do
              1 ->
                {:error, %KeyError{key: invalid_tuples |> Keyword.keys() |> hd, term: value}}

              _ ->
                {:error, %KeyError{key: invalid_tuples |> Keyword.keys(), term: value}}
            end
        end

      true ->
        new_error_result(m: "opts not derivable", v: value)
    end
  end

  @doc false
  def reduce_mappers(mappers \\ []) do
    mappers
    |> list_wrap_flat_just
    |> case do
      [fun] -> fun
      funs -> fn v -> funs |> Enum.reduce(v, fn f, s -> f.(s) end) end
    end
  end

  @doc false
  def value_validate_by_predicate(value, pred)

  def value_validate_by_predicate(value, pred) when is_function(pred, 1) do
    value
    |> pred.()
    |> case do
      x when x in [nil, false] ->
        new_error_result(m: "value failed predicate", v: value)

      _ ->
        {:ok, value}
    end
  end

  def value_validate_by_predicate(_value, pred) do
    new_error_result(m: "predicate invalid", v: pred)
  end

  @since "0.1.0"

  @spec validate_key_alias_dict(any) :: {:ok, alias_dict} | {:error, error}

  defp validate_key_alias_dict(dict)

  defp validate_key_alias_dict(dict) when is_map(dict) do
    with true <- dict |> Map.keys() |> Enum.all?(&is_atom/1),
         true <- dict |> Map.values() |> Enum.all?(&is_atom/1) do
      {:ok, dict}
    else
      false -> new_error_result(m: "key alias dict invalid", v: dict)
    end
  end

  @doc false

  @since "0.1.0"

  @spec normalise_key_alias_dict(any) :: {:ok, alias_dict} | {:error, error}

  def normalise_key_alias_dict(dict)

  def normalise_key_alias_dict(dict) when is_map(dict) do
    dict |> validate_key_alias_dict
  end

  def normalise_key_alias_dict(dict) when is_list(dict) do
    cond do
      Keyword.keyword?(dict) ->
        dict |> Enum.into(%{}) |> validate_key_alias_dict

      true ->
        new_error_result(m: "key alias dict invalid", v: dict)
    end
  end

  def normalise_key_alias_dict(dict) do
    new_error_result(m: "key alias dict invalid", v: dict)
  end

  @since "0.1.0"

  defp opts_create_alias_tuples(aliases) do
    aliases
    |> Enum.map(fn
      {k, nil} ->
        {k, k}

      {k, a} ->
        [k | a |> List.wrap()]
        |> Enum.uniq()
        |> Enum.map(fn a -> {a, k} end)
    end)
    |> List.flatten()
  end

  @doc ~S"""
  `opts_create_aliases_dict/1` does the same job as `opts_create_alias_tuples/1` but returns a *key alias dict*.

  ## Examples

      iex> [a: nil, b: [:b1], c: [:c1, :c2, :c3]] |> opts_create_aliases_dict
      %{a: :a, b: :b, b1: :b, c: :c, c1: :c, c2: :c, c3: :c}

  """

  @since "0.1.0"

  @spec opts_create_aliases_dict(alias_kvs) :: alias_dict

  def opts_create_aliases_dict(aliases) do
    aliases
    |> opts_create_alias_tuples
    |> Enum.into(%{})
  end

  @doc ~S"""
  `opts_canon_keys!/2` takes an opts list, together with a lookup dictionary and replaces each key with its canonical value from the dictionary. Unknown keys raise a `KeyError`.

  ## Examples

      iex> [a: 1, b: 2, c: 3] |> opts_canon_keys!(%{a: :x, b: :y, c: :z})
      [x: 1, y: 2, z: 3]

      iex> [x: 1, y: 3, z: 3] |> opts_canon_keys!(%{a: 1, b: 2, c: 3})
      ** (KeyError) key :x not found in: %{a: 1, b: 2, c: 3}

  """

  @spec opts_canon_keys!(opts, alias_dict) :: opts | no_return

  def opts_canon_keys!(opts, dict) when is_map(dict) do
    opts |> Enum.map(fn {k, v} -> {dict |> Map.fetch!(k), v} end)
  end

  @doc ~S"""
  `opts_canon_keys/2` takes an opts list, together with a lookup dictionary and replaces each key with its canonical value from the dictionary, returning `{:ok, opts}`.

  If there are any unknown keys, `{:error, {known_opts, unknown_opts}}` is returned.

  ## Examples

      iex> [a: 1, b: 2, c: 3] |> opts_canon_keys(%{a: :x, b: :y, c: :z})
      {:ok, [x: 1, y: 2, z: 3]}

      iex> [a: 11, p: 1, b: 22, q: 2, c: 33, r: 3] |> opts_canon_keys(%{a: :x, b: :y, c: :z})
      {:error, {[x: 11, y: 22, z: 33], [p: 1, q: 2, r: 3]}}

  """

  @spec opts_canon_keys(opts, alias_dict) :: {:ok, opts} | {:error, {opts, opts}}

  def opts_canon_keys(opts, dict) when is_map(dict) do
    opts
    # split into known and unknown keys
    |> Enum.split_with(fn {k, _v} -> Map.has_key?(dict, k) end)
    |> case do
      # no unknown keys
      {known_kvs, []} ->
        {:ok, known_kvs |> opts_canon_keys!(dict)}

      {known_kvs, unknown_kvs} ->
        {:error, {known_kvs |> opts_canon_keys!(dict), unknown_kvs}}
    end
  end

  @doc ~S"""
  `opts_maybe_canon_keys/2` takes an opts list, together with a lookup dictionary and replaces any key in the dictionary with its dictionary value, returning the updated opts.

  ## Examples

      iex> [a: 1, b: 2, c: 3] |> opts_maybe_canon_keys(%{a: :x, b: :y, c: :z})
      [x: 1, y: 2, z: 3]

      iex> [a: 11, p: 1, b: 22, q: 2, c: 33, r: 3] |> opts_maybe_canon_keys(%{a: :x, b: :y, c: :z})
      [x: 11, p: 1, y: 22, q: 2, z: 33, r: 3]

  """

  @spec opts_maybe_canon_keys(opts, alias_dict) :: {:ok, opts}

  def opts_maybe_canon_keys(opts, dict) when is_list(opts) and is_map(dict) do
    opts
    |> Enum.map(fn {k, v} ->
      case dict |> Map.has_key?(k) do
        true -> {Map.get(dict, k), v}
        _ -> {k, v}
      end
    end)
  end

  @doc ~S"""
  `opts_canonical_keys/2` takes a *derivable opts*, together with a *key alias dict*.

  Each key in the `opts` is replaced with its (canonical) value from the dictionary, returning `{:ok, canon_opts}`.

  If there are any unknown keys, `{:error, error}`, where `error` is a `KeyError`, will be returned.

  ## Examples

      iex> [a: 1, b: 2, c: 3] |> opts_canonical_keys(%{a: :x, b: :y, c: :z})
      {:ok, [x: 1, y: 2, z: 3]}

      iex> [a: 1, b: 2, c: 3] |> opts_canonical_keys([a: :x, b: :y, c: :z])
      {:ok, [x: 1, y: 2, z: 3]}

      iex> [a: 11, p: 1, b: 22, q: 2, c: 33, r: 3] |> opts_canonical_keys(%{a: :x, b: :y, c: :z})
      {:error, %KeyError{key: [:p, :q, :r], term: %{a: :x, b: :y, c: :z}}}

      iex> {:error, error} = [a: 1, b: 2, c: 3]
      ...> |> opts_canonical_keys([a_canon: :a, b_canon: [:b], c_canon: [:c, :cc]])
      ...> error |> Exception.message
      "key alias dict invalid, got: %{a_canon: :a, b_canon: [:b], c_canon: [:c, :cc]}"

  """

  @since "0.1.0"

  @spec opts_canonical_keys(opts, alias_dict) :: {:ok, opts} | {:error, error}

  def opts_canonical_keys(opts, dict)

  def opts_canonical_keys([], _dict) do
    {:ok, []}
  end

  def opts_canonical_keys(opts, dict) do
    with {:ok, opts} <- opts |> opts_normalise,
         {:ok, dict} <- dict |> normalise_key_alias_dict do
      opts
      # reject known_keys
      |> Enum.reject(fn {k, _v} -> Map.has_key?(dict, k) end)
      |> case do
        # no unknown keys
        [] ->
          canon_tuples =
            opts
            |> Enum.map(fn {k, v} -> {Map.get(dict, k), v} end)

          {:ok, canon_tuples}

        unknown_tuples ->
          unknown_tuples |> new_key_error_result(dict)
      end
    else
      {:error, _} = result -> result
    end
  end

  @doc ~S"""
  `opts_validate_keys!/2` takes an opts list, together with the list of valid keys, and check there are no unknown keys in opts, raising a `KeyError` if so, else returning the opts.

  ## Examples

      iex> [a: 1, b: 2, c: 3] |> opts_validate_keys!([:a, :b, :c])
      [a: 1, b: 2, c: 3]

      iex> [a: 1, b: 2, c: 3] |> opts_validate_keys!([:a, :b])
      ** (KeyError) key [:c] not found in: [:a, :b]

      iex> [a: 1, b: 2, c: 3] |> opts_validate_keys!([])
      [a: 1, b: 2, c: 3]

  """

  @spec opts_validate_keys!(opts, list) :: opts | no_return

  def opts_validate_keys!(opts, known_keys)

  def opts_validate_keys!(opts, []) do
    opts
  end

  def opts_validate_keys!(opts, known_keys) when is_list(opts) and is_list(known_keys) do
    opts
    |> Keyword.keys()
    |> Enum.uniq()
    |> Kernel.--(known_keys)
    |> case do
      # no unknown known_keys
      [] ->
        opts

      # unknown known_keys
      unknown_keys ->
        raise KeyError, key: unknown_keys, term: known_keys
    end
  end

  @doc ~S"""
  `opts_sort_keys/` takes an opts list, together with a list of sort keys, and returns the opts sorted in the sort keys order. Duplicate keys follow one after another.

  Any keys found but not given in the sort keys follow the sorted keys in the returned opts.
  Any key in the sort list not found in the opts is ignored.

  ## Examples

      iex> [a: 1, b: 2, c: 3, d: 4] |> opts_sort_keys([:c, :a])
      [c: 3, a: 1,  b: 2, d: 4]

      iex> [a: 1, b: 2, c: 3, d: 4] |> opts_sort_keys([:d, :x, :b, :z])
      [d: 4, b: 2, a: 1, c: 3]

  """

  @spec opts_sort_keys(opts, alias_keys) :: opts

  def opts_sort_keys(opts, keys \\ [])

  def opts_sort_keys([], _keys) do
    []
  end

  def opts_sort_keys(opts, []) do
    opts
  end

  def opts_sort_keys(opts, keys) do
    with {:ok, opts} <- opts |> opts_normalise,
         # add all the opts' keys to the sort order ones
         {:ok, keys} <- (keys ++ Keyword.keys(opts)) |> normalise_keys do
      keys
      |> Enum.uniq()
      |> Enum.flat_map(fn k ->
        opts
        |> Keyword.get_values(k)
        |> Enum.map(fn v -> {k, v} end)
      end)
    else
      {:error, %{__exception__: true} = error} -> raise error
    end
  end

  @doc ~S"""
  `map_collate0_enum/2` take an *enum* and *map/1 function* and
  applies the arity 1 function to each element of the *enum* in an
  `Enum.reduce_while/2` loop.

  The mapper must return either `{:ok, value}` or `{:error, error}`.

  If the latter, the `Enum.reduce_while/2` is halted, returning the
  `{:error, error}`.

  Otherwise the `value` from each `{:ok, value}` result are collected
  into a list and `{:ok, values}` returned.

  ## Examples

      iex> fun = fn v -> {:ok, v} end
      ...> [1,2,3] |> map_collate0_enum(fun)
      {:ok, [1,2,3]}

      iex> fun = fn
      ...>  3 -> {:error, %ArgumentError{message: "argument is 3"}}
      ...>  v -> {:ok, v}
      ...> end
      ...> {:error, error} = [1,2,3] |> map_collate0_enum(fun)
      ...> error |> Exception.message
      "argument is 3"

      iex> fun = :not_a_fun
      ...> {:error, error} = [1,2,3] |> map_collate0_enum(fun)
      ...> error |> Exception.message
      "fun/1 function invalid, got: :not_a_fun"

      iex> fun = fn v -> {:ok, v} end
      ...> {:error, error} = 42 |> map_collate0_enum(fun)
      ...> error |> Exception.message
      "enum invalid, got: 42"

  """

  @since "0.1.0"

  @spec map_collate0_enum(any, any) :: {:ok, list} | {:error, error}

  def map_collate0_enum(enum, fun)

  def map_collate0_enum(enum, fun) when is_function(fun, 1) do
    try do
      enum
      |> Enum.reduce_while(
        [],
        fn value, values ->
          value
          |> fun.()
          |> case do
            {:error, %{__struct__: _}} = result -> {:halt, result}
            {:ok, value} -> {:cont, [value | values]}
            value -> {:halt, new_error_result(m: "pattern0 result invalid", v: value)}
          end
        end
      )
      |> case do
        {:error, %{__exception__: true}} = result -> result
        values -> {:ok, values |> Enum.reverse()}
      end
    rescue
      _ ->
        new_error_result(m: "enum invalid", v: enum)
    end
  end

  def map_collate0_enum(_enum, fun) do
    new_error_result(m: "fun/1 function invalid", v: fun)
  end

  @doc ~S"""
  `form_validate/1` calls `Macro.validate/1` on the argument (the expected *form*)
  and if the result is `:ok` returns {:ok, form}, else `{:error, error}`.

  ## Examples

      iex> 1 |> form_validate
      {:ok, 1}

      iex> nil |> form_validate # nil is a valid ast
      {:ok, nil}

      iex> [:x, :y] |> form_validate
      {:ok, [:x, :y]}

      iex> form = {:x, :y} # this 2tuple is a valid form without escaping
      ...> form |> form_validate
      {:ok, {:x, :y}}

      iex> {:error, error} = {:x, :y, :z} |> form_validate
      ...> error |> Exception.message
      "form invalid, got: {:x, :y, :z}"

      iex> {:error, error} = %{a: 1, b: 2, c: 3} |> form_validate # map not a valid form
      ...> error |> Exception.message
      "form invalid, got: %{a: 1, b: 2, c: 3}"

      iex> form = %{a: 1, b: 2, c: 3} |> Macro.escape # escaped map is a valid form
      ...> form |> form_validate
      {:ok,  %{a: 1, b: 2, c: 3} |> Macro.escape}

  """

  @since "0.1.0"

  @spec form_validate(any) :: {:ok, form} | {:error, error}

  def form_validate(form)

  def form_validate(form) do
    case form |> Macro.validate() do
      :ok -> {:ok, form}
      {:error, _remainder} -> new_error_result(m: "form invalid", v: form)
    end
  end

  @doc ~S"""

  `forms_validate/1` validates the *forms* using `form_validate/1` on each *form*, returning `{:ok, forms}` if all are valid, else `{:error, error}`.

  ## Examples

      iex> [1, 2, 3] |> forms_validate
      {:ok, [1, 2, 3]}

      iex> [1, {2, 2}, :three] |> forms_validate
      {:ok, [1, {2, 2}, :three]}

      iex> {:error, error} = [1, {2, 2, 2}, %{c: 3}] |> forms_validate
      ...> error |> Exception.message
      "forms invalid, got invalid indices: [1, 2]"

  """

  @since "0.1.0"

  @spec forms_validate(any) :: {:ok, forms} | {:error, error}

  def forms_validate(forms)

  def forms_validate(forms) when is_list(forms) do
    forms
    |> Stream.with_index()
    |> Enum.reduce(
      [],
      fn {form, index}, invalid_indices ->
        case form |> form_validate do
          {:ok, _} -> invalid_indices
          {:error, _} -> [index | invalid_indices]
        end
      end
    )
    |> case do
      # no invalid forms
      [] ->
        {:ok, forms}

      invalid_indices ->
        new_error_result(
          m: "forms invalid, got invalid indices: #{inspect(Enum.reverse(invalid_indices))}"
        )
    end
  end

  def forms_validate(forms) do
    new_error_result(m: "forms invalid", v: forms)
  end

  @doc ~S"""
  `forms_reduce/1` takes a zero, one or more *form*, normalises them, and reduces the *forms* to a single
  *form* using `Kernel.SpecialForms.unquote_splicing/1`.

  If the reduction suceeds, `{:ok, reduced_form}` is returned, else `{:error, error}`.

  An empty list reduces to `{:ok, nil}`.

  ## Examples

      iex> {:ok, reduced_form} = quote(do: a = x + y) |> forms_reduce
      ...> reduced_form |> Macro.to_string
      "a = x + y"

      iex> {:ok, reduced_form} = [
      ...>  quote(do: a = x + y),
      ...>  quote(do: a * c)
      ...> ] |> forms_reduce
      ...> reduced_form |> Macro.to_string
      "(\n  a = x + y\n  a * c\n)"

      iex> {:ok, form} = nil |> forms_reduce
      ...> form |> Macro.to_string
      "nil"

      iex> {:ok, form} = [
      ...>  quote(do: a = x + y),
      ...>  nil,
      ...>  [
      ...>   quote(do: b = a / c),
      ...>   nil,
      ...>   quote(do: d = b * b),
      ...>  ],
      ...>  quote(do: e = a + d),
      ...> ] |> forms_reduce
      ...> form |> Macro.to_string
      "(\n  a = x + y\n  b = a / c\n  d = b * b\n  e = a + d\n)"

  """

  @since "0.1.0"

  @spec forms_reduce(any) :: {:ok, form} | {:error, error}

  def forms_reduce(asts \\ [])

  def forms_reduce([]), do: {:ok, nil}

  def forms_reduce(forms) do
    with {:ok, forms} <- forms |> forms_normalise do
      forms
      |> case do
        x when is_nil(x) ->
          {:ok, nil}

        forms ->
          forms
          |> length
          |> case do
            0 ->
              {:ok, nil}

            1 ->
              {:ok, forms |> List.first()}

            _ ->
              form =
                quote do
                  (unquote_splicing(forms))
                end

              {:ok, form}
          end
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `forms_normalise/1` takes zero, one or more *form* and normalises them to a *forms* returning `{:ok, forms}`.

  The list is first flattened and any `nils` removed before splicing.

  ## Examples

      iex> {:ok, forms} = quote(do: a = x + y) |> forms_normalise
      ...> forms |> hd |> Macro.to_string
      "a = x + y"

      iex> {:ok, forms} = [
      ...>  quote(do: a = x + y),
      ...>  quote(do: a * c)
      ...> ] |> forms_normalise
      ...> forms |> Macro.to_string
      "[a = x + y, a * c]"

      iex> nil |> forms_normalise
      {:ok, []}

      iex> {:ok, form} = [
      ...>  quote(do: a = x + y),
      ...>  nil,
      ...>  [
      ...>   quote(do: b = a / c),
      ...>   nil,
      ...>   quote(do: d = b * b),
      ...>  ],
      ...>  quote(do: e = a + d),
      ...> ] |> forms_normalise
      ...> form |> Macro.to_string
      "[a = x + y, b = a / c, d = b * b, e = a + d]"

  """

  @since "0.1.0"

  @spec forms_normalise(any) :: {:ok, forms} | {:error, error}

  def forms_normalise(forms \\ [])

  def forms_normalise(forms) do
    forms
    |> list_wrap_flat_just
    |> forms_validate
    |> case do
      # {:ok, []} -> {:ok, nil}
      {:ok, _} = result ->
        result

      {:error, %{__struct__: _}} = result ->
        result
    end
  end

  @doc false
  def value_telltale(value)

  def value_telltale(value)

  def value_telltale(value)
      when is_atom(value) or is_number(value) or is_bitstring(value) or is_function(value) do
    value |> inspect
  end

  def value_telltale(value) do
    cond do
      Exception.exception?(value) -> value |> Exception.message()
      :ok = Macro.validate(value) -> value |> Macro.to_string()
      true -> value |> inspect
    end
  end
end
