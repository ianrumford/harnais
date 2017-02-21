defmodule Harnais.Runner.Run do

  @moduledoc false

  require Logger
  import ExUnit.Assertions
  use Harnais.Attributes
  import Harnais.Accessors

  defp run_test_mfas(test_value, test_mfas) do

    # Note: mfa must be "complete" i.e. have all args

    test_value |> Harnais.Utils.Transforms.harnais_transforms_apply(test_mfas)

  end

  def run_test_spec(test_spec) do

    test_flag = test_spec |> spec_test_flag_get(@harnais_opts_key_test_flag_default)

    case test_flag do

      {:e, exception} ->

        assert_raise exception, fn ->
          run_test_mfas(test_spec.test_value, test_spec.test_mfas)
        end

        {test_spec.test_value, test_spec}

      flag ->

        actual = run_test_mfas(test_spec.test_value, test_spec.test_mfas)

        # if a test_actual, compare (assert) with it.
        case test_spec.test_result do

          expect when expect != nil ->

            cond do

              # if test_actual is a fun, let it do comparision and
              # assert its return
              is_function(expect, 1) -> assert expect.(actual)
              is_function(expect, 2) -> assert expect.(actual, test_spec)

              true ->

                  case expect do

                    ^actual -> actual

                    # assert the failure
                    _ ->

                        assert expect == actual

                  end

            end

          _ ->

            actual

        end

        # if flag was a write, return the actual for next cycle
        case flag do
          :w -> {actual, test_spec}
          _ -> {test_spec.test_value, test_spec}
        end

    end

  end

  def spec_run_tests(spec) do

    fn_test_runner = spec |> spec_test_runner_fetch!

    test_value = spec |> spec_test_value_get

    spec
    |> spec_test_specs_get([])
    |> Enum.reduce(test_value, fn_test_runner)

    spec

  end

end

