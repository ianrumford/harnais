ExUnit.start()

defmodule HarnaisHelpersTest do

  defmacro __using__(_opts \\ []) do

    quote do
      use ExUnit.Case, async: true
      use Harnais
      alias Harnais.Runner.Normalise, as: HRN
    end

  end

end

