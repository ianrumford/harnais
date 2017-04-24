defmodule Harnais.Utils.Transforms do

  @moduledoc false

  use Harnais.Attributes

  defp transform_reduce_mfa_with_accumulator(fun, s) when is_function(fun) do
    fun.(s)
  end

  defp transform_reduce_mfa_with_accumulator({fun, nil}, s) when is_function(fun) do
    fun.(s)
  end

  defp transform_reduce_mfa_with_accumulator({f, a}, s) when is_function(f) and is_list(a) do
    apply(f, [s | a])
  end

  defp transform_reduce_mfa_with_accumulator({m, f}, s) do
    apply(m, f, [s])
  end

  defp transform_reduce_mfa_with_accumulator({m, f, a}, s) when is_list(a) do
    apply(m, f, [s | a])
  end

  defp transform_reduce_mfa_with_accumulator({m, f, a}, _s) when is_tuple(a) do
    apply(m, f, a |> Tuple.to_list)
  end

  def harnais_transforms_apply(value, mfas \\ [])

  def harnais_transforms_apply(value, []), do: value

  def harnais_transforms_apply(value, mfas) do

    value = mfas
    |> List.wrap
    |> Enum.reduce(value,
    fn v, s ->

      transform_reduce_mfa_with_accumulator(v, s)

    end)

    value

  end

end

