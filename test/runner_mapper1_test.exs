defmodule HarnaisExampleMapperRunner1Test do

  use HarnaisHelpersTest

  test "test_mapper: single arity 1" do

    test_namer = fn name -> Harnais.Bootstrap.name_to_atom(name) end

    test_value = @harnais_state_deep

    Harnais.run_tests_default_test_value(
      test_module: Map,
      test_namer: test_namer,
      test_value: test_value,

      test_mapper: fn {test_call, test_args} ->

        # test_value is from outside closure and module is explicit
        test_result = apply(Map, test_call, [test_value | test_args ])

        [test_call: test_call, test_args: test_args, test_result: test_result]

      end,

      test_specs: [
        {:get, [:a]},
        {:put, [:d, 4]},
        {:pop, [:c]},
        ])

    end

  test "test_mapper: multiple 1" do

    test_namer = fn name -> Harnais.Bootstrap.name_to_atom(name) end

    test_value = @harnais_state_deep

    Harnais.run_tests_default_test_value(
      test_module: Map,
      test_namer: test_namer,
      test_value: test_value,

      test_mapper: [
      fn
        :get -> {:get, [:a]}
        :put -> {:get, [:d, 4]}
        test_call -> {test_call, []}
      end,
      fn {test_call, test_args} ->

        # test_value is from outside closure and module is explicit
        test_result = apply(Map, test_call, [test_value | test_args ])

        [test_call: test_call, test_args: test_args, test_result: test_result]

      end,
      ],

      test_specs: [
        :get,
        :put,
        :keys,
        :values
      ])

  end

  test "test_mapper: single arity 2" do

    test_namer = fn name -> Harnais.Bootstrap.name_to_atom(name) end

    test_value = @harnais_state_deep

    Harnais.run_tests_default_test_value(
      test_module: Map,
      test_namer: test_namer,
      test_value: test_value,

      test_mapper: fn {test_call, test_args}, spec ->

        test_value = spec |> Map.get(:test_value)

        test_module = spec |> Map.get(:test_module)

        test_result = apply(test_module, test_call, [test_value | test_args ])

        [test_call: test_call, test_args: test_args, test_result: test_result]

      end,

      test_specs: [
        {:get, [:a]},

      ])

  end

end

