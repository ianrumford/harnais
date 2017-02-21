defmodule HarnaisExampleDefaultMapRunner1Test do

  use HarnaisHelpersTest

  test "ex_runner_map1: [:b]" do

    test_namer = fn name -> Harnais.Bootstrap.name_to_atom(name) end

    test_value = @harnais_state_deep

    Harnais.run_tests_default_test_value(
      test_module: Map,
      test_namer: test_namer,
      test_value: test_value,
      test_specs: [
        {:r, :get, [:b, 42], @harnais_state_deep_b},
        {:r, :get, [:b, 42], 42, %{}},
        {:r, :get, [:b, 42], 42, %{a: %{}}},
        {{:e, BadMapError}, :get, [:a], nil, nil},

        {:r, :fetch!, [:b], @harnais_state_deep_b},
        {{:e, KeyError}, :fetch!, [:d]},

        {:r, :fetch, [:b], {:ok, @harnais_state_deep_b}},
        {:r, :fetch, [:b], :error, %{a: %{}}},
        {:r, :fetch, [:b], {:ok, 42}, %{b: 42}},
        {:r, :fetch, [:b], :error, %{}},

        {:w, :put, [:b, 42], Map.put(test_value, :b, 42)},
        {:w, :put, [:b, 42], %{b: 42}, %{}},

        {:w, :put_new, [:b, 42], test_value},
        {:w, :put_new, [:b, 42], %{b: 42}, %{}},

        {:w, :put_new_lazy, [:b, fn -> 42 end], test_value},
        {:w, :put_new_lazy, [:b, fn -> 42 end], %{b: 42}, %{}},

        {:r, :has_key?, [:b], true},
        {:r, :has_key?, [:b], false, %{}},
        {:r, :has_key?, [:b], true, %{b: %{}}},

        {:w, :delete, [:b], Map.delete(test_value, :b)},
        {:w, :delete, [:b], @harnais_state_deep_c, @harnais_state_deep_c},
        {:w, :delete, [:b], %{}, %{}},
        {:w, :delete, [:b], %{}, %{b: %{b2: 11}}},

        {:w, :take, [[:b, :c]], Map.take(test_value, [:b, :c])},
        {:w, :take, [[:b]], %{}, @harnais_state_deep_c},
        {:w, :take, [[:b]], %{}, %{}},

        {:w, :drop, [[:b]], Map.delete(test_value, :b)},
        {:w, :drop, [[:b]], @harnais_state_deep_c, @harnais_state_deep_c},
        {:w, :drop, [[:b]], %{}, %{b: %{}}},
        {:w, :drop, [[:b]], %{}, %{}},

        {:w, :merge, [%{d: 4}], Map.merge(test_value, %{d: 4})},
        {:w, :merge, [%{d: 4}], %{b: 2, d: 4}, %{b: 2}},

        {:r, :keys, [], [:a, :b, :c]},
        {:r, :keys, [], [], %{}},
        {:r, :keys, [], [:b], %{b: %{b2: %{}}}},
        {:r, :keys, [], [:b], %{b: %{b2: %{b21: 21}}}},

        {:r, :values, [], Map.values(test_value)},
        {:r, :values, [], [], %{}},
        {:r, :values, [], [%{b2: %{}}], %{b: %{b2: %{}}}},
        {:r, :values, [], [1, 2, 3], %{a: 1, b: 2, c: 3}},

        {:r, :equal?, [@harnais_state_deep], true},
        {:r, :equal?, [%{}], false},
        {{:e, FunctionClauseError}, :equal?, [[]], false},

        # size is now deprecated
        # {:r, :size, [], 3},
        # {:r, :size, [], 1, %{b: %{b2: %{}}}},

        {:r, :split, [[:b2]], {Map.take(@harnais_state_deep_b, [:b2]), Map.drop(@harnais_state_deep_b, [:b2])}, @harnais_state_deep_b},
        {:r, :split, [[:b2]], {%{b2: %{}}, %{b1: %{}}}, %{b1: %{}, b2: %{}}},

        {:r, :to_list, [], test_value |> Map.to_list},
        {:r, :to_list, [], [b: %{b2: %{}}], %{b: %{b2: %{}}}},
        {:r, :to_list, [], [], %{}},

        {:w, :update, [:b, 42, &(&1)], test_value},
        {:w, :update, [:b, 42, fn _ -> 99 end],  %{b: 99}, %{b: 2}},
        {:w, :update, [:b, 42, fn _ -> 99 end],  %{b: 42}, %{}},

        {:w, :update!, [:b, &(&1)], test_value},
        {:w, :update!, [:b, fn _ -> 99 end],  Map.put(test_value, :b, 99)},

      ],

    )

  end

end

