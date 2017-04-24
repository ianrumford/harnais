defmodule HarnaisExampleSuiteMap1Test do

  use HarnaisHelpersTest

  test "ex_runner_map1: [:b]" do

    test_value = @harnais_state_deep

    Harnais.run_tests_default_test_value(
      d: Map,
      v: test_value,
      t: Harnais.Runner.Suites.Map.tests_get(:default))

  end

end

