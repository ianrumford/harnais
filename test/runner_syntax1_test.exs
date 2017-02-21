defmodule HarnaisExampleSyntaxRunner1Test do

  use HarnaisHelpersTest

  test "runner_syntax1: [:b]" do

    test_namer = fn name -> Harnais.Bootstrap.name_to_atom(name) end

    test_value = @harnais_state_deep

    Harnais.run_tests_default_test_value(
      d: Map,
      n: test_namer,
      v: test_value,
      t: [

        # errors
        [{:e, BadMapError}, :get, [:b], nil, nil],
        [{:e, UndefinedFunctionError}, :blah, [:b], nil, nil],

        # tuple form
        {:r, :get, [:b], @harnais_state_deep_b},
        {:r, :get, [:b, 42], @harnais_state_deep_b},

        # tuple form; with test_value
        {:r, :get, [:b], 2, %{b: 2}},
        {:r, :get, [:b, 42], 42, %{}},

        # list form
        [:r, :get, [:b], @harnais_state_deep_b],
        [:r, :get, [:b, 42], @harnais_state_deep_b],

        # list form; with test_value
        [:r, :get, [:b], 2, %{b: 2}],
        [:r, :get, [:b, 42], 42, %{}],

        # keyword form
        [test_flag: :r, test_call: :get, test_args: [:b], test_result: @harnais_state_deep_b],
        [test_flag: :r, test_call: :get, test_args: [:b, 42], test_result: @harnais_state_deep_b],

        # keyword form using aliases
        [f: :r, c: :get, a: [:b], r: @harnais_state_deep_b],
        [f: :r, c: :get, a: [:b, 42], r: @harnais_state_deep_b],

        # keyword form; with test_value
        [test_flag: :r, test_call: :get, test_args: [:b], test_result: 2, test_value: %{b: 2}],
        [test_flag: :r, test_call: :get, test_args: [:b, 42], test_result: 42, test_value: %{}],

        # keyword form using aliases; with test_value
        [f: :r, c: :get, a: [:b], r: 2, v: %{b: 2}],
        [f: :r, c: :get, a: [:b, 42], r: 42, v: %{}],

        # map form
        %{test_flag: :r, test_call: :get, test_args: [:b], test_result: @harnais_state_deep_b},
        %{test_flag: :r, test_call: :get, test_args: [:b, 42], test_result: @harnais_state_deep_b},

        # map form using aliases
        %{f: :r, c: :get, a: [:b], r: @harnais_state_deep_b},
        %{f: :r, c: :get, a: [:b, 42], r: @harnais_state_deep_b},

        # map form; with test_value
        %{test_flag: :r, test_call: :get, test_args: [:b], test_result: 2, test_value: %{b: 2}},
        %{test_flag: :r, test_call: :get, test_args: [:b, 42], test_result: 42, test_value: %{}},

        # map form using aliases; with test_value
        %{f: :r, c: :get, a: [:b], r: 2, test_value: %{b: 2}},
        %{f: :r, c: :get, a: [:b, 42], r: 42, v: %{}},

        # call spec: single mfa
        [:r, {Map, :get, [:b]}, nil, 2, %{b: 2}],
        [:r, {Map, :get, [:b, 42]}, nil, 42, %{}],

        # call spec: multiple mfa
        [c: [{Map, :get, [:b, %{}]}, {Map, :put, [:b22, 22]}], r: %{b21: 21, b22: 22}, v: %{b: %{b21: 21}}],

        # call spec: single {m,f,a} but a is a tuple => *all* args and ignore test_value
        [c: {Map, :get, {%{b: 2}, :b}}, v:  %{a: 1}, r: 2],
        [c: {Map, :put, {%{a: 1}, :b, 42}}, v:  %{a: 1}, r: %{a: 1, b: 42}],

        # call spec: single fun
        [:r, fn %{b: 2} -> 2 end, nil, 2, %{b: 2}],
        [:r, fn %{b: 2} -> 2 end, [], 2, %{b: 2}],
        [:r, fn %{b: 2}, :a, 1 -> 2 end, [:a, 1], 2, %{b: 2}],

        {:r, fn %{b: 2} -> 2 end, nil, 2, %{b: 2}},
        {:r, fn %{b: 2} -> 2 end, [], 2, %{b: 2}},
        {:r, fn %{b: 2}, :a, 1 -> 2 end, [:a, 1], 2, %{b: 2}},

        [c: fn %{b: 2} -> 2 end, r: 2,  v: %{b: 2}],
        [c: fn %{b: 2} -> 2 end, a: [], r: 2, v: %{b: 2}],
        [c: fn %{b: 2}, :a, 1 -> 2 end, a: [:a, 1], r: 2, v: %{b: 2}],

        # call spec: multiple fun
        [c: [fn %{b: 2} -> 2 end, fn x -> x * x end], r: 4,  v: %{b: 2}],
        [c: [fn %{b: 2} -> 2 end, fn x -> x * x * x end], a: [], r: 8, v: %{b: 2}],
        [c: [fn %{b: 2}, :a, 1 -> 2 end, fn _x -> 42 end], a: [:a, 1], r: 42, v: %{b: 2}],

        # call spec: mfa + fun
        [c: [{Map, :get, [:b]}, fn x -> x + 100 end], r: 102, v: %{b: 2}],

        # call spec: nil => just compare
        [c: nil, r: %{b: 2}, v: %{b: 2}],
        [r: %{b: 2}, v: %{b: 2}],

        # using a function to validate the result
        [c: :get, a: [:b], r: fn v -> v == 2 end, v: %{a: 1, b: 2, c: 3}],
        [c: :put, a: [:d, 4], r: fn m -> map_size(m) == 4 end, v: %{a: 1, b: 2, c: 3}],

      ])

  end

end

