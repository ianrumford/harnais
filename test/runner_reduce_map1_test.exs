defmodule HarnaisExampleReduceMapRunner1Test do

  use HarnaisHelpersTest

  test "ex_runner_map1: [:b]" do

    test_namer = fn name -> Harnais.Bootstrap.name_to_atom(name) end

    test_value = @harnais_state_deep

    Harnais.run_tests_reduce_test_value(
      test_module: Map,
      test_namer: test_namer,
      test_value: test_value,
      tests: [

        # :w => update the test_value to the result of the get
        {:w, :get, [:b, 42], @harnais_state_deep_b},
        # :r => don't change current test_value i.e. passthru
        [:r, :keys, [], Map.keys(@harnais_state_deep_b)],
        [:r, :values, [], Map.values(@harnais_state_deep_b)],
        [:r, :to_list, [], Map.to_list(@harnais_state_deep_b)],
        # update test_value
        [f: :w, c: {Kernel, :map_size, []}, r: 2],
        [c: fn x -> x * x end, r: 4],

        # reset test_value and update to result of get
        [f: :w, c: :get, a: [:a, 42], r: Map.get(test_value, :a), v: test_value],
        # just compare / assert
        [r: Map.get(test_value, :a)],

      ])

  end

end

