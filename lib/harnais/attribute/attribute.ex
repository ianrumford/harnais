defmodule Harnais.Attribute do
  @moduledoc false

  defmacro __using__(_opts \\ []) do
    quote do
      @harnais_key_struct_id :__struct__

      @harnais_key_compare_module :compare_module
      @harnais_key_compare_mfas :compare_mfas
      @harnais_key_compare_keys :compare_keys
      @harnais_key_filter_keys :filter_keys
      @harnais_key_compare_values :compare_values
      @harnais_key_transform_list :transform_list
    end
  end
end
