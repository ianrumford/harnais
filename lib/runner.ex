defmodule Harnais.Runner do

  @moduledoc ~S"""
  A harness for writing and running `ExUnit` tests

  `Harnais.Runner` supports multiple ways of defining a test -- see [The Test Specification](#module-the-test-specification) below.

  Errors (exceptions) can be caught; a test expected to fail is wrapped in an `ExUnit.Assertions.assert_raise/2`.

  Most of the keys (e.g. `:test_value`) have short forms (e.g. `:v`); the [aliases are given below](#module-the-key-aliases).

  ## Test Runners

  `Harnais.Runner` has 3 different test runners, distinguished by how they select the test value for each test.

  > Note the main `Harnais` module delegates to the test runners in `Harnais.Runner`.

  ### Test Runner - run_tests_default_test_value

  The test runner `Harnais.run_tests_default_test_value/1` uses the default `:test_value`,
  unless overridden by a test-specific value.

      iex> Harnais.run_tests_default_test_value(
      ...> # the default module to test
      ...> test_module: Map,
      ...> # the default test value
      ...> test_value: %{a: 1, b: 2, c: 3},
      ...> # the tests
      ...> test_specifications: [
      ...>  # using full key names
      ...>  [test_call: :get, test_args: [:c], test_result: 3],
      ...>  # using key aliases
      ...>  [call: :get, args: [:c], result: 3],
      ...>  [c: :get, a: [:c], r: 3],
      ...>  # with a test-specific test value (v is an alias of test_value)
      ...>  [c: :get, a: [:c], r: 42, v: %{c: 42}],
      ...>  # using list format - the first item is the test_flag (nil in this test)
      ...>  [nil, :put, [:d, 4], %{a: 1, b: 2, c: 3, d: 4}],
      ...>  [nil, :put, [:d, 4], %{d: 4}, %{}],
      ...>  # using tuple format - the first item is the test_flag (nil in next two tests)
      ...>  {nil, :put, [:d, 4], %{a: 1, b: 2, c: 3, d: 4}},
      ...>  {nil, :put, [:d, 4], %{d: 4}, %{}},
      ...>  # using map format with alias keys
      ...>  %{c: :put, a: [:d, 4], r: %{a: 1, b: 2, c: 3, d: 4}},
      ...>  %{c: :put, a: [:d, 4], r: %{d: 4}, v: %{}},
      ...>  # use a function rather that the test_module
      ...>  [c: fn test_value -> Kernel.map_size(test_value) + 2 end, r: 5],
      ...>  # use MFA format call rather that the test_module + test_args
      ...>  [c: {Kernel, :map_size, []}, r: 3],
      ...>  # MFA-like but args is a tuple => Tuple.to_list and *ignore* test_value
      ...>  [c: {Map, :get, {%{b: 2}, :b}}, v:  %{a: 1}, r: 2],
      ...>  [c: {Map, :put, {%{a: 1}, :b, 42}}, v:  %{a: 1}, r: %{a: 1, b: 42}],
      ...>  # a pipeline (Enum.reduce/3) of calls: e.g. MFA + fun + fun
      ...>  [c: [{Kernel, :map_size, []}, fn v -> v * v end, fn v -> v - 5 end], r: 4],
      ...>  # using a function to validate the result
      ...>  [c: :get, a: [:b], r: fn v -> v == 2 end, v: %{a: 1, b: 2, c: 3}],
      ...>  [c: :put, a: [:d, 4], r: fn m -> map_size(m) == 4 end, v: %{a: 1, b: 2, c: 3}],
      ...>  # catch some errors - the test_flag is set to a 2tuple {:e, ExceptionName}
      ...>  [f: {:e, BadMapError}, c: :get, a: [:x], r: nil, v: []],
      ...>  [f: {:e, BadMapError}, c: :put, a: [:x, 42], r: nil, v: nil],
      ...>  [f: {:e, UndefinedFunctionError}, c: :not_a_fun, a: [:x, 42], r: nil, v: nil],
      ...>  [f: {:e, FunctionClauseError}, c: {Kernel, :put_in, [:b, :b21]}, r: nil, v: %{b: 42}],
      ...> ])
      :ok

  ### Test Runner - run_tests_reduce_test_value

  Using the test runner `Harnais.run_tests_reduce_test_value/1` offers
  more control of the test value from test to test,  allowing the
  result of the last test to be set as the value for the next test: to
  do so requires the `:test_flag` to be set to *:w* ("write").

  Alternatively, the `:test_value` can be reinitialised by including an explicit
  value in the test specification.

      iex> Harnais.run_tests_reduce_test_value(
      ...> # the default module to test
      ...> test_module: Map,
      ...> # the default test value
      ...> value: %{a: 1, b: %{b21: 21, b22: 22}, c: 3},
      ...> t: [
      ...>  # get value of :b and make it the input for next test - note flag is :w
      ...>  {:w, :get, [:b], %{b21: 21, b22: 22}},
      ...>  # use the value of b for some tests
      ...>  {:r, :keys, [], [:b21, :b22]},
      ...>  {:r, :to_list, [], [b21: 21, b22: 22]},
      ...>  # update the test value to the list of values
      ...>  {:w, :values, [], [21, 22]},
      ...>  # now update the test value again, adding the two values
      ...>  {:w, fn [v1, v2] -> v1 + v2 end, [], 43},
      ...>  # confirm test_value now result of previous test
      ...>  [r: 43],
      ...>  # provide an explicit test_value to reinitialise test value and update again
      ...>  {:w, :get, [:d], 4, %{d: 4}},
      ...>  # apply a function
      ...>  [f: :w, c: fn v -> v * v end, r: 16],
      ...>  # confirmation again
      ...>  [r: 16],
      ...> ])
      :ok

  ### Test Runner - run_tests_same_test_value

  The final runner, `Harnais.run_tests_same_test_value/1`, **always** uses the
  `:test_value` given to the runner, ignoring any test-specific value
  (or *:w* flags).

      iex> Harnais.run_tests_same_test_value(
      ...> # the default module to test
      ...> d: Map,
      ...> # the default test value
      ...> v: %{a: 1, b: 2, c: 3},
      ...> t: [
      ...>  # always use the test_value above
      ...>  [c: :get, a: [:c], r: 3, v: %{c: 42}],
      ...>  {:w, :put, [:d, 4], %{a: 1, b: 2, c: 3, d: 4}, v: %{c: 42}},
      ...>  [c: fn v -> Kernel.map_size(v) + 2 end, r: 5, v: %{c: 42}],
      ...> ])
      :ok

  ## Test Runner Options

  The supported options to the test runner are:

  ### `:test_module`

  The name of the default module to use in the `:test_call`

  ### `:test_value`

  The default value passed as the first argument to the `:test_call`

  ### `:test_mapper`

  See [The Test Mappper](#module-the-test-mapper) below.

  ### `:test_namer`

  When the `:test_call` is a function name (i.e. `Atom`), the namer function is called with the function name and should return the actual function to call in the `:test_module`.

  ### `:test_specifications`

  The `:test_specifications` is one or more (`List`) test specifications.

  ## The Test Specification

  A `test spec` can be defined in either of a number of formats: tuple, list, keyword and map.

  After it has been *normalised*, the `test spec` become a `Map` and the keys have their canonical names (e.g. `:test_value` not `:v`).

  ### Test Spec: tuple form

  4tuple and 5tuple forms are supported where the elements map to:

      {test_flag, test_call, test_args, test_result}
      {test_flag, test_call, test_args, test_result, test_value}

  ### Test Spec: list form

  The order of elements in the `List` form is the same as the tuple:

      [test_flag, test_call, test_args, test_result]
      [test_flag, test_call, test_args, test_result, test_value]

  ### Test Spec: keyword form

  The `Keyword` form is as expected, here using key aliases,  e.g.

      [c: :get, a: [:c], r: 3]

  ### Test Spec: map form

    Similarly the `Map` form e.g.

      %{call: :get, args: [:c], r: 3}

  ## The Test Call Specification

  The test call is one or more (`List`) of call specifications:

  The valid forms of the `call spec` are:

  ### Test Call - `function name` (`Atom`)

    The name of a function (e.g. *:get*) to call in the default `test_module`

  ### Test Call - `function`

    An arity one function to be called with the `test_value`

  ### Test Call - `MFA`

    An MFA tuple ({module, function, args} where the args are a (maybe empty) list.

    The `test_value` will be added as first argument of the args.

  ### Test Call - `MFA-like` but args is a tuple

    In this case the args tuple is converted to a list (`Tuple.to_list/1`) to form *all* the arguments; the `test_value` is ignored.

  ### Test Call - `nil`

    `nil` implies just compare (assert) the test value is the same as the `test_result`.

  ## The Test Flag

  The `:test_flag` is optional in the `Map` and `Keyword` test forms
  but required in the positional `Tuple` and `List` forms.

  Even when required, usually the `:test_flag` can be nil; it is ignored.

  The `:test_flag` is most frequently used to catch an exception e.g. `{:e ArgumentError}`.

  The flag is important though when using the runner
  `Harnais.run_tests_reduce_test_value/1` as described above when a
  value of `:w` will set the `:test_value` for the next test to the
  result of the current test.

  ## The Test Mapper

  Each test in the `:test_specs` can be mapped using a `:test_mapper` values that must be one or more functions.

  Each function must have arity one or two.

  An arity one mapper is passed just the `test spec` as it has been given in the tests.

  Any arity two mapper is passed both the `test spec` and the `run spec`. The `run spec` is a `Map` of all the options passed the the test runner and may have keys such as `:test_module`, `:test_value`, `:test_call` as well as all the tests held in the `:test_specs` key.

  Each mapper is applied to the `test spec` in an `Enum.reduce/3` pipeline.

  > The last mapper must return one of the valid forms of a `test spec` (see multi function example below).

  This example is not specific to
  `Harnais.run_tests_default_test_value/1` but is intended to show how
  a mapper   can be used to build the `Keyword` form of the `test
  spec`.

  In this simple example, the mapper finds the expected `test result`
  directly from the `test value` in the `run spec` and builds the
  `test spec`. (*In essence the mapper "second guesses" the test.*)

      iex> Harnais.run_tests_default_test_value(
      ...> d: Map,
      ...> v: %{a: 1, b: 2, c: 3},
      ...> mapper: fn {test_call, test_args}, run_spec ->
      ...>   test_module = run_spec |> Map.fetch!(:test_module)
      ...>   test_value = run_spec |> Map.fetch!(:test_value)
      ...>   test_result = apply(test_module, test_call, [test_value | test_args])
      ...>   # final test_spec
      ...>   [c: test_call, a: test_args, r: test_result]
      ...> end,
      ...> tests: [
      ...>  {:get, [:a]},
      ...>  {:put, [:d, 4]},
      ...>  {:has_key?, [:d]},
      ...> ])
      :ok

   This example is a variation of the above one but showing three mappers and different arities.

      iex> test_namer = fn name -> "#{name}" |> String.to_atom end
      ...> test_value = %{a: 1, b: 2, c: 3}
      ...> Harnais.run_tests_default_test_value(
      ...> d: Map,
      ...> v: test_value,
      ...> m: [
      ...> test_namer,
      ...> fn
      ...>   :get -> {:get, [:a]}
      ...>   :put -> {:get, [:d, 4]}
      ...>   test_call -> {test_call, []}
      ...> end,
      ...> fn {test_call, test_args}, run_spec ->
      ...>   test_value = run_spec |> Map.fetch!(:test_value)
      ...>   test_result = apply(Map, test_call, [test_value | test_args])
      ...>   [c: test_call, a: test_args, r: test_result]
      ...> end],
      ...> t: ["get", :put, "keys", :values])
      :ok

  ## The Test Result

  Each `test spec` must have a `:test_result` key.

  If the `test result` is a function of arity one, it is called with the actual result, and the result of the function asserted.

 If the `test result` is a function of arity two, it is called with the actual result *and* the *normalised* `test spec` (`Map`), and the result of the function asserted.

  ## The Key Aliases

  These are the key aliases:

    * `:test_flag`   -- `:f`, `:flag`
    * `:test_call`   -- `:c`, `:call`
    * `:test_args`   -- `:a`, `:args`
    * `:test_result` -- `:r`, `:result`
    * `:test_value`  -- `:v`, `:value`
    * `:test_specifications`  -- `:t`, `:tests`, `:specs`, `:test_specs`
    * `:test_module` -- `:d`, `:module`
    * `:test_namer`  -- `:n`, `:namer`
    * `:test_mapper` -- `:m`, `:mapper`

  """

  require Logger

  use Harnais.Attributes
  import Harnais.Accessors
  alias Harnais.Runner.Normalise, as: HRN
  alias Harnais.Runner.Run, as: HRR

  @type test_flag ::
  nil |
  :r |
  :w |
  {:e, atom}

  @type test_module :: atom
  @type test_function :: atom
  @type test_mapper :: (any -> any) | (any, map -> any)
  @type test_namer :: fun
  @type test_value :: any
  @type test_args :: nil | [any]
  @type test_result :: any | (any -> any) | (any, map -> any)

  @type test_call_spec_mfa :: {test_module, test_function, test_args}
  @type test_call_spec_fun :: fun

  @type test_call_spec ::
  test_call_spec_fun |
  test_call_spec_mfa

  @type test_call :: nil | test_call_spec

  @type test_spec_tuple ::
  {test_flag, test_call, test_args, test_result} |
  {test_flag, test_call, test_args, test_result, test_value}

  @type test_spec_map :: %{

    optional(:test_module) => test_module,
    optional(:test_call) => test_call,
    optional(:test_namer) => test_namer,
    optional(:test_value) => test_value,
    required(:test_result) => test_result,

    }

  @type test_spec ::
  test_spec_tuple |
  test_spec_map

  @type test_specs :: test_spec | [test_spec]
  @type test_spec_normalise :: fun
  @type test_spec_runner :: fun

  @type runner_option ::
  {:test_module, atom} |
  {:test_mapper, test_mapper} |
  {:test_namer, test_namer} |
  {:test_value, test_value} |
  {:test_specs, test_specs}

  @typedoc "The options passed to Harnais.Runner test runners."
  @type runner_options :: [runner_option]

  @doc false
  def run_tests_same_test_runner(test_spec, test_value) do

    test_spec
    |> Map.put(:test_value, test_value)
    |> HRR.run_test_spec

    # alway return the passed accumulator
    test_value

  end

  def run_tests_same_test_value(opts \\ []) do

    opts
    |> HRN.spec_normalise
    |> spec_test_runner_put(&run_tests_same_test_runner/2)
    |> HRR.spec_run_tests

    :ok

  end

  @doc false
  def run_tests_default_test_runner(test_spec, test_value) do

    # need a test value?
    case test_spec |> Map.has_key?(:test_value) do
      true -> test_spec
      _ -> test_spec |> Map.put(:test_value, test_value)
    end
    |> HRR.run_test_spec

    # alway return the passed accumulator
    test_value

  end

  def run_tests_default_test_value(opts \\ []) do

    opts
    |> HRN.spec_normalise
    |> spec_test_runner_put(&run_tests_default_test_runner/2)
    |> HRR.spec_run_tests

    :ok

  end

  @doc false
  def run_tests_reduce_test_runner(test_spec, test_value) do

    # restart reduce if test_spec has a test_value
    case test_spec |> Map.has_key?(:test_value) do
      true -> test_spec
      _ -> test_spec |> Map.put(:test_value, test_value)
    end
    |> HRR.run_test_spec
    # return the result
    |> elem(0)

  end

  def run_tests_reduce_test_value(opts \\ []) do

    opts
    |> HRN.spec_normalise
    |> spec_test_runner_put(&run_tests_reduce_test_runner/2)
    |> HRR.spec_run_tests

    :ok

  end

end

