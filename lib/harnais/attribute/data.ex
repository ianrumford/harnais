defmodule Harnais.Attribute.Data do
  @moduledoc false

  defmacro __using__(_opts \\ []) do
    quote do
      use Harnais.Bootstrap

      @harnais_list_alphabet_a_z ?a..?z
                                 |> Enum.map(fn x -> <<x::utf8>> end)
                                 |> Enum.map(&String.to_atom/1)

      @harnais_list_alphabet_a_z_tuples Enum.zip(@harnais_list_alphabet_a_z, 1..26)

      @harnais_list_alphabet_a_z_map @harnais_list_alphabet_a_z_tuples |> Enum.into(%{})

      @harnais_opts_none %{}
      @harnais_opts_some %{x: 101, y: 102, z: 103}
      @harnais_opts_keyl Keyword.new([{:p, 1001}, {:q, 1002}, {:r, 1003}])
      @harnais_opts_keyl_map @harnais_opts_keyl |> Enum.into(%{})

      @harnais_opts_keyl_none []
      @harnais_opts_keyl_some [{:a, 1}, {:b, 2}, {:c, 3}]

      @harnais_state_none %{}
      @harnais_state_some %{a: 1, b: 2, c: 3}
      @harnais_state_mpqr %{p: 11, q: 12, r: 13}
      @harnais_state_nils %{a: nil, b: nil, c: nil}

      @harnais_state_none_a nil
      @harnais_state_some_a 1

      @harnais_state_deep_a %{a1: 1}

      @harnais_state_deep_b_b2_b22 %{b221: 221, b222: 222}

      @harnais_state_deep_b_b2 %{b21: 21, b22: @harnais_state_deep_b_b2_b22}

      @harnais_state_deep_b %{b1: 21, b2: @harnais_state_deep_b_b2}

      @harnais_state_deep_c_c31 31
      @harnais_state_deep_c_c32 %{c21: 321, c22: %{c221: 3221, c222: 3222}}

      @harnais_state_deep_c_c33 %{
        c31: 331,
        c32: %{c321: 3321, c322: %{c3221: 33221, c3222: 33222}},
        c33: %{c331: 3331, c332: %{c3321: 33321, c3332: %{c33221: 333_221, c33222: 333_222}}}
      }

      @harnais_state_deep_c %{
        c1: @harnais_state_deep_c_c31,
        c2: @harnais_state_deep_c_c32,
        c3: @harnais_state_deep_c_c33
      }

      @harnais_state_deep %{
        a: @harnais_state_deep_a,
        b: @harnais_state_deep_b,
        c: @harnais_state_deep_c
      }

      @harnais_state_none_2tuples @harnais_state_none |> Map.to_list()
      @harnais_state_some_2tuples @harnais_state_some |> Map.to_list()
      @harnais_state_deep_2tuples @harnais_state_deep |> Map.to_list()

      @harnais_state_none_flat_keys @harnais_state_none

      @harnais_state_some_flat_keys @harnais_state_some
                                    |> harnais_map_convert_keys_to_list

      @harnais_state_deep_c_c32_flat_keys %{
        [:c21] => 321,
        [:c22, :c221] => 3221,
        [:c22, :c222] => 3222
      }

      @harnais_state_deep_flat_keys %{
        [:a, :a1] => 1,
        [:b, :b1] => 21,
        [:b, :b2, :b21] => 21,
        [:b, :b2, :b22, :b221] => 221,
        [:b, :b2, :b22, :b222] => 222,
        [:c, :c1] => 31,
        [:c, :c2, :c21] => 321,
        [:c, :c2, :c22, :c221] => 3221,
        [:c, :c2, :c22, :c222] => 3222,
        [:c, :c3, :c31] => 331,
        [:c, :c3, :c32, :c321] => 3321,
        [:c, :c3, :c32, :c322, :c3221] => 33221,
        [:c, :c3, :c32, :c322, :c3222] => 33222,
        [:c, :c3, :c33, :c331] => 3331,
        [:c, :c3, :c33, :c332, :c3321] => 33321,
        [:c, :c3, :c33, :c332, :c3332, :c33221] => 333_221,
        [:c, :c3, :c33, :c332, :c3332, :c33222] => 333_222
      }

      @harnais_state_none_flat_keys_2tuples @harnais_state_none_flat_keys |> Map.to_list()
      @harnais_state_some_flat_keys_2tuples @harnais_state_some_flat_keys |> Map.to_list()
      @harnais_state_deep_flat_keys_2tuples @harnais_state_deep_flat_keys |> Map.to_list()
      @harnais_state_deep_c_c32_flat_keys_2tuples @harnais_state_deep_c_c32_flat_keys
                                                  |> Map.to_list()
    end
  end
end
