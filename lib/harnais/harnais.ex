defmodule Harnais do
  @moduledoc ~S"""
  `Harnais` is a family of harnesses for testing Elixir code.

  ## Standard Result API

  Many functions return either {:ok, any} or {:error, error} where
  `error` will be an `Exception`.

  Peer bang functions return either value or raises error.

  """

  @type opts :: Keyword.t()
  @type error :: struct
  @type ast :: Macro.t()
  @type asts :: [ast]
  @type form :: Macro.t()
  @type forms :: [form]
  @type key :: atom
  @type keys :: [key]

  @doc ~S"""
  The __using__ macro initialises `Harnais`.

  ## Examples

      use Harnais

  """

  defmacro __using__(_opts \\ []) do
    quote do
      use Harnais.Bootstrap
      use Harnais.Attribute
    end
  end
end
