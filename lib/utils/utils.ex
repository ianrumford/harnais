defmodule Harnais.Utils.Utils do

  @moduledoc false

  import ExUnit.Assertions
  alias Harnais.Utils.Maps, as: HUM
  use Harnais.Attributes

  def harnais_assert_equal(x, y), do: assert x == y

  def harnais_new_opts_map_none, do: @harnais_opts_none
  def harnais_new_opts_map_some, do: @harnais_opts_some

  def harnais_new_opts_key_none, do: @harnais_opts_keyl_none
  def harnais_new_opts_key_some, do: @harnais_opts_keyl_some

  def harnais_new_opts_keyl, do: @harnais_opts_keyl
  def harnais_new_opts_keyl_map, do: @harnais_opts_keyl_map

  def harnais_make_fun_compare_state_value(comp_state, key) do

    comp_value = comp_state |> HUM.map_lens_get(key)

    fn test_value ->

      case test_value == comp_value do

        true -> true

        _ ->

          false

      end

    end

  end

  def harnais_make_fun_compare_state_value_tag(comp_state, key) do

    comp_value = comp_state
    |> HUM.map_lens_get(key)
    |> harnais_tag_value

    fn test_value ->

      case test_value == comp_value do

        true -> true

        _ ->

          false

      end

    end

  end

 def harnais_tag_value(value) do

   cond do

     is_nil(value) -> {:nil, value}
     is_map(value) -> {:map, value}
     is_atom(value) -> {:atom, value}
     is_binary(value) -> {:string, value}
     is_integer(value) -> {:integer, value}

     true -> {:unknown, value}

   end

  end

 def harnais_analyse_state_monad_result({result_value, _result_state} = result_tuple) do

   cond do

     is_nil(result_value) -> {:nil, result_tuple}
     is_map(result_value) -> {:map, result_tuple}
     is_atom(result_value) -> {:atom, result_tuple}
     is_binary(result_value) -> {:string, result_tuple}
     is_integer(result_value) -> {:integer, result_tuple}

     true -> {:unknown, result_tuple}

   end

 end

end
