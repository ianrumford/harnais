defmodule Harnais do

  @moduledoc ~S"""
  `Harnais` is a harness for writing and running Elxiir tests.

  It tries to minimise the boilerplate, and make it as
  convenient as possible to write concise suites of tests.
  """

  defdelegate run_tests_default_test_value(opts), to: Harnais.Runner
  defdelegate run_tests_same_test_value(opts), to: Harnais.Runner
  defdelegate run_tests_reduce_test_value(opts), to: Harnais.Runner

  @doc ~S"""
  The __using__ macro initialises the `Harnais` harness.

      use Harnais

  """

  defmacro __using__(_opts \\ []) do

    quote do

      use Harnais.Attributes

    end

  end

end

