ExUnit.start()

defmodule HarnaisHelperTest do
  defmacro __using__(_opts \\ []) do
    quote do
      use ExUnit.Case, async: true
      use Harnais
      use Harnais.Attribute
    end
  end
end
