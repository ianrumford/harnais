defmodule Harnais.Utils.Maps do

  @moduledoc false

  import ExUnit.Assertions
  use Harnais.Attributes

  @harnais_utils_maps_struct_key :__struct__

  def harnais_map_put_ins(state, put_ins) when is_map(state) and is_list(put_ins) do

    # normalise the put_ins to 2tuples
    put_ins = put_ins
    |> Enum.chunk(2)
    |> Enum.map(
    fn
      [{k1,v1}, {k2,v2}] -> [{k1,v1}, {k2,v2}]
      [k,v] -> {k,v}
    end)
    |> List.flatten

    state = put_ins
    |> Enum.reduce(state, fn {keys, value}, s -> Kernel.put_in(s, keys |> List.wrap, value) end)

    state

  end

  def harnais_map_get_ins(state, get_ins) when is_map(state) and is_list(get_ins) do

    get_ins = get_ins
    |> Enum.reduce([], fn keys, s -> [Kernel.get_in(state, keys |> List.wrap) | s] end)
    |> Enum.reverse

    get_ins

  end

  def harnais_map_get_in(state, get_in) do
    state |> harnais_map_get_ins([get_in]) |> List.first
  end

  # TRANSITION
  def new_map_none, do: @harnais_state_none
  def new_map_some, do: @harnais_state_some
  def new_map_deep, do: @harnais_state_deep
  def new_map_nils, do: @harnais_state_nils
  def new_map_mpqr, do: @harnais_state_mpqr

  def harnais_new_state_none do
    @harnais_state_none
  end

  def harnais_new_state_some do
    @harnais_state_some
  end

  def harnais_new_state_deep() do
    @harnais_state_deep
  end

  def harnais_assert_state_equal(state1, state2) do
    assert state1 == state2
    state1
  end

  def harnais_assert_state_key_equal(state, key, value) do
    assert value == state |> Map.get(key)
    state
  end

  # TRANSITION
  def new_state_none, do: @harnais_state_none
  def new_state_some, do: @harnais_state_some
  def new_state_deep, do: @harnais_state_deep

  def new_state_deep_a, do: @harnais_state_deep_a
  def new_state_deep_b, do: @harnais_state_deep_b
  def new_state_deep_c, do: @harnais_state_deep_c
  def new_state_deep_c_c33, do: @harnais_state_deep_c_c33

  defp map_lens_keys_normalise([]), do: []
  defp map_lens_keys_normalise(keys) when is_list(keys), do: keys
  defp map_lens_keys_normalise(keys), do: [keys]

  def map_lens_create_keys_recursive(lens, []) when is_map(lens), do: lens

  def map_lens_create_keys_recursive(lens, keys) when is_map(lens) and is_list(keys) do

    [key | keys_rest] = keys

    lens =
      case lens do
        %{^key => value}
          -> Map.put(lens, key, map_lens_create_keys_recursive(value, keys_rest))
        _ -> Map.put(lens, key, map_lens_create_keys_recursive(%{}, keys_rest))
      end

   lens

  end

  # header
  def map_lens_get_in(lens, keys, default \\ nil)

  def map_lens_get_in(lens, keys, default) when is_map(lens) and is_list(keys),
    do: Kernel.get_in(lens, map_lens_keys_normalise(keys)) || default

  def map_lens_get_in(lens, key, default) when is_map(lens), do: Map.get(lens, key, default)

  def map_lens_put_in(lens, keys, value) when is_map(lens) and is_list(keys) do
    lens |> Kernel.put_in(map_lens_keys_normalise(keys), value)
  end

  def map_lens_put_in(lens, key, value) when is_map(lens) do
   lens |>  Map.put(key, value)
  end

  def map_lens_assoc_in(lens, keys, value) when is_map(lens) and is_list(keys) do

    try do

      map_lens_put_in(lens, keys, value)

    catch _type, _error ->

      # need to (try to) create the intermediate keys and try again
      keys = map_lens_keys_normalise(keys)
      Kernel.put_in(map_lens_create_keys_recursive(lens, List.delete_at(keys, -1)),
                    keys,
                    value)

    end

  end

  def map_lens_assoc_in(lens, key, value) when is_map(lens), do: Map.put(lens, key, value)

  def map_lens_fetch_in!(lens, keys) when is_map(lens) and is_list(keys) do

    case map_lens_has_key_in?(lens, keys) do

      true -> map_lens_get_in(lens, keys)

      _ -> raise KeyError, key: keys, term: lens

    end

  end

  def map_lens_fetch_in!(lens, key) when is_map(lens), do: Map.fetch!(lens, key)

  def map_lens_has_key_in?(lens, []) when is_map(lens), do: false

  def map_lens_has_key_in?(lens, keys) when is_map(lens) and is_list(keys) do

    [key | keys_rest] = keys

    result =
      case lens do

        %{^key => value} ->

          # any more keys?
          case length(keys_rest) do
            0 -> true
            _ -> map_lens_has_key_in?(value, keys_rest)
          end

          _ -> false

      end

    result

  end

  def map_lens_has_key_in?(lens, key) when is_map(lens), do: lens |> Map.has_key?(key)

  # header
  def map_lens_get(lens, keys, default \\ nil)

  def map_lens_get(lens, [key | []], default) when is_map(lens) do
    lens |> map_lens_get(key, default)
  end

  def map_lens_get(lens, [key | keys], default) when is_map(lens) do
    case Map.has_key?(lens, key) do
      true -> lens |> Map.get(key) |> map_lens_get(keys, default)
      _ -> default
    end
  end

  def map_lens_get(lens, key, default) when is_map(lens) do
    lens |> Map.get(key, default)
  end

  def map_lens_get(lens, _key, _default),
  do: raise BadMapError, term: lens

  # header
  def map_lens_get_or_default(lens, keys, default \\ nil)

  def map_lens_get_or_default(lens, [key | []], default) when is_map(lens),
    do: lens |> map_lens_get_or_default(key, default)

  def map_lens_get_or_default(lens, [key | keys], default) when is_map(lens) do
    case Map.has_key?(lens, key) do
      true -> lens |> Map.get(key) |> map_lens_get_or_default(keys, default)
      _ -> default
    end
  end

  def map_lens_get_or_default(lens, key, default) when is_map(lens) do
    Map.get(lens, key) || default
  end

  def map_lens_fetch!(lens, [key | []]) when is_map(lens),
    do: lens |> Map.fetch!(key)

  def map_lens_fetch!(lens, [key | keys]) when is_map(lens),
    do: lens |> Map.fetch!(key) |> map_lens_fetch!(keys)

  def map_lens_fetch!(lens, key) when is_map(lens), do: lens |> Map.fetch!(key)

  def map_lens_fetch!(lens, _key) do
    raise BadMapError, term: lens
  end

  defp map_lens_put_by_kind(%{@harnais_utils_maps_struct_key => _} = lens, key, value) do
    # structs always have the key if it is a valid key
    case Map.has_key?(lens, key) do
      true -> lens |> Map.put(key, value)
      _ -> raise KeyError, key: key, term: lens
    end
  end

  defp map_lens_put_by_kind(lens, key, value) when is_map(lens), do: lens |> Map.put(key, value)

  def map_lens_put(lens, [key | []], value) when is_map(lens) do
    lens |> map_lens_put(key, value)
  end

  def map_lens_put(lens, [key | keys], value) when is_map(lens) do
    lens
    |> map_lens_put_by_kind(key, lens |> Map.get(key) |> map_lens_put(keys, value))
  end

  def map_lens_put(lens, key, value) when is_map(lens) do
    lens |> map_lens_put_by_kind(key, value)
  end

  def map_lens_put(lens, key, _value) do
    raise KeyError, key: key, term: lens
  end

  def map_lens_assoc(lens, [key | []], value) when is_map(lens) do
    lens |>  map_lens_assoc(key, value)
  end

  def map_lens_assoc(lens, [key | keys], value) when is_map(lens) do
    lens
    |> map_lens_put_by_kind(key, lens |> Map.get(key, %{}) |> map_lens_assoc(keys, value))
  end

  def map_lens_assoc(lens, key, value) when is_map(lens) do
    lens |> map_lens_put_by_kind(key, value)
  end

  def map_lens_assoc(lens, _key, _value) do
    raise BadMapError, term: lens
  end

  def map_lens_delete(lens, [key | []]) when is_map(lens), do: lens |> Map.delete(key)

  def map_lens_delete(lens, [key | keys]) when is_map(lens) do
    case Map.has_key?(lens, key) do
      true -> lens |> Map.put(key, lens |> Map.get(key) |> map_lens_delete(keys))
      _ -> lens
    end
  end

  def map_lens_delete(lens, key) when is_map(lens), do: lens |> Map.delete(key)

  def map_lens_delete(lens, _key) do
    raise BadMapError, term: lens
  end

  def map_lens_has_key?(lens, []) when is_map(lens), do: false

  def map_lens_has_key?(lens, [key | []]) when is_map(lens), do: map_lens_has_key?(lens, key)

  def map_lens_has_key?(lens, [key | keys]) when is_map(lens) do
    case lens do

      # key exists?
      %{^key => value} ->

        # any more keys to find?
        case length(keys) do
          # nop all done and sucess
          0 -> true
          _ -> map_lens_has_key?(value, keys)
        end

      _ -> false

    end

  end

  def map_lens_has_key?(lens, key) when is_map(lens), do: Map.has_key?(lens, key)

  def map_lens_has_key?(lens, _key) do
    raise BadMapError, term: lens
  end

  def map_lens_update!(lens, [key | []], fun) when is_map(lens) do
   lens |> map_lens_update!(key, fun)
  end

  def map_lens_update!(lens, [key | keys], fun) when is_map(lens) do
    lens
    |> map_lens_put(key,
    case Map.fetch!(lens, key) do
      x when is_map(x) -> x |> map_lens_update!(keys, fun)
      _ ->
        raise KeyError, key: key, term: lens
    end)
  end

  def map_lens_update!(lens, key, fun) when is_map(lens), do: lens |> Map.update!(key, fun)

  def map_lens_update(lens, [key | []], initial_value, fun) when is_map(lens) do
    lens |> map_lens_update(key, initial_value, fun)
  end

  # struct
  def map_lens_update(%{@harnais_utils_maps_struct_key => _struct_module} = lens, [key | keys], initial_value, fun) when is_map(lens) do

    lens
    |> map_lens_put(key,

    # note: a struct will always have a known key
    case Map.get(lens, key) do

      x when is_map(x) -> x |> map_lens_update(keys, initial_value, fun)

      # if key is nil, create a map and descend
      x when is_nil(x) -> %{} |> map_lens_update(keys, initial_value, fun)

      _ ->
        raise KeyError, key: key, term: lens

    end)

  end

  # map
  def map_lens_update(lens, [key | keys], initial_value, fun) when is_map(lens) do

    lens
    |> map_lens_put(key,

    case Map.has_key?(lens, key) do

      true ->

        case Map.get(lens, key) do
          x when is_map(x) -> x |> map_lens_update(keys, initial_value, fun)

          _ ->
            raise KeyError, key: key, term: lens
        end

        # if no key, create a map and descend
        _ -> %{} |> map_lens_update(keys, initial_value, fun)

    end)

  end

  # struct
  def map_lens_update(%{@harnais_utils_maps_struct_key => _} = lens, key, initial_value, fun) when is_map(lens) do

    case Map.get(lens, key) do

      x when x != nil -> lens |> Map.update(key, initial_value, fun)

      # if nil, put the initial value
      _ -> lens |> Map.put(key, initial_value)

    end

  end

  # map
  def map_lens_update(lens, key, initial_value, fun) when is_map(lens), do: lens |> Map.update(key, initial_value, fun)

  def map_lens_drop(lens, []), do: lens

  # a list with one list inside => leaf
  def map_lens_drop(lens, [keys]) when is_list(keys), do: lens |> Map.drop(keys)

  def map_lens_drop(lens, keys) when is_list(keys) do

    {node_keys, leaf_keys} = keys |> Enum.split(-1)

    # the leaf must be the list of keys to map_lens_drop
    true = is_list(List.last(leaf_keys))

    lens = case map_lens_get(lens, node_keys) do

           leaf_value when leaf_value != nil ->

             lens |> map_lens_put(node_keys, leaf_value |> map_lens_drop(leaf_keys))

             # leaf not found => nothing to do
             _ -> lens

         end

    lens

  end

  def map_lens_take(lens, []), do: lens

  # a list with one list inside => leaf
  def map_lens_take(lens, [keys]) when is_list(keys), do: lens |> Map.take(keys)

  def map_lens_take(lens, keys) when is_list(keys) do

    {node_keys, leaf_keys} = keys |> Enum.split(-1)

    # the leaf must be the list of keys to map_lens_take
    true = is_list(List.last(leaf_keys))

    lens = case map_lens_get(lens, node_keys) do

             leaf_value when leaf_value != nil ->

               lens |> map_lens_put(node_keys, leaf_value |> map_lens_take(leaf_keys))

               # leaf not found => nothing to do
               _ -> lens

           end

    lens

  end

  defp map_lens_reconcile_worker(lens1, lens2, fn_reconcile)
  when is_map(lens1) and is_map(lens2) and is_function(fn_reconcile, 3) do

    lens3 = lens2
    # build update tuples
    |> Enum.reduce(
      lens1,
      fn {k,v}, lens1 ->

        case Map.has_key?(lens1, k) do

          # if true, reconcile the subkeys.
          true ->

            case fn_reconcile.(k, Map.get(lens1, k), v) do

              # if not nil, one or more 2tuples
              x when x != nil ->

                x
                |> List.wrap
                |> Enum.into(lens1)

              # nil => drop the key
              _ -> lens1 |> Map.drop([k])

            end

            # no key in lens1; update with new key value pair
            _ -> lens1 |> Map.put(k, v)

        end

      end)

    lens3

  end

  def map_lens_reconcile(lens1, list1, fn_reconcile) when is_map(lens1) and is_list(list1),
    do: map_lens_reconcile(lens1, list1 |> Enum.into(%{}), fn_reconcile)

  def map_lens_reconcile(lens1, lens2, fn_reconcile) when is_map(lens1) and is_map(lens2),
    do: map_lens_reconcile_worker(lens1, lens2, fn_reconcile)

  defp map_lens_merge_reconcile(_k, lens1, lens2) when is_map(lens1) and not is_map(lens2),
    do: raise BadMapError, term: lens2

  defp map_lens_merge_reconcile(_k, lens1, lens2) when not is_map(lens1) and is_map(lens2),
    do: raise BadMapError, term: lens1

  defp map_lens_merge_reconcile(_k, v1, v2) when is_map(v1) and is_map(v2) do
    map_lens_merge(v1, v2)
  end

  # default => use v2
  defp map_lens_merge_reconcile(_k, _v1, v2) do
    v2
  end

  def map_lens_merge(lens1, lens2, fn_reconcile \\ &map_lens_merge_reconcile/3) when is_map(lens1) do

    # need to create a fun that observes map_lens_reconcile semantics
    # i.e. return nil or one or more tuples
    fun = fn k, v1, v2 -> {k, fn_reconcile.(k, v1, v2)} end

    map_lens_reconcile(lens1, lens2, fun)
  end

  # default => use v2
  defp map_lens_update_reconcile(k, _v1, v2), do: {k, v2}

  def map_lens_update(lens1, lens2, fn_reconcile \\ &map_lens_update_reconcile/3) when is_map(lens1),
    do: map_lens_reconcile(lens1, lens2, fn_reconcile)

end

