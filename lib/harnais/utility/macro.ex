defmodule Harnais.Utility.Macro do
  @moduledoc false

  defmacro def_struct_get(_opts \\ []) do
    quote do
      def struct_get(%{__struct__: _} = state, key, default \\ nil) do
        state
        |> Map.get(key)
        |> case do
          @plymio_fontais_the_unset_value ->
            {:ok, default}

          x ->
            {:ok, x}
        end
      end
    end
  end

  defmacro def_struct_fetch(_opts \\ []) do
    quote do
      def struct_fetch(%{__struct__: _} = state, key) do
        state
        |> Map.get(key)
        |> case do
          @plymio_fontais_the_unset_value ->
            new_error_result(m: "struct key #{to_string(key)} not set")

          x ->
            {:ok, x}
        end
      end
    end
  end

  defmacro def_struct_put(_opts \\ []) do
    quote do
      def struct_put(%{__struct__: _} = state, key, value) do
        {:ok, state |> struct!([{key, value}])}
      end
    end
  end

  # delete sets the value back to "not set"
  defmacro def_struct_delete(_opts \\ []) do
    quote do
      def struct_delete(%{__struct__: _} = state, key) do
        {:ok, state |> struct_put(key, @plymio_fontais_the_unset_value)}
      end
    end
  end

  defmacro custom_struct_accessors(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      trace_telltale = "CUSTOM_STRUCT_ACC=BINDQ"

      specs = opts |> Keyword.fetch!(:specs)

      namer = opts |> Keyword.fetch!(:namer)

      specs
      |> Enum.flat_map(fn {name, spec} ->
        spec
        |> Map.get(:funs)
        |> Enum.map(fn fun ->
          fun_name = namer.(name, fun)

          case fun do
            :get ->
              quote do
                def unquote(fun_name)(state, default \\ nil) do
                  struct_get(state, unquote(name), default)
                end
              end

            :fetch ->
              quote do
                def unquote(fun_name)(state) do
                  struct_fetch(state, unquote(name))
                end
              end

            :put ->
              quote do
                def unquote(fun_name)(state, value) do
                  struct_put(state, unquote(name), value)
                end
              end

            :maybe_put ->
              fun_name_fetch = namer.(name, :fetch)

              quote do
                def unquote(fun_name)(state, value) do
                  with {:ok, _} <- state |> unquote(fun_name_fetch)() do
                    {:ok, state}
                  else
                    _ -> struct_put(state, unquote(name), value)
                  end
                end
              end

            :delete ->
              quote do
                def unquote(fun_name)(state) do
                  struct_delete(state, unquote(name))
                end
              end
          end
        end)
      end)
      |> Code.eval_quoted([], __ENV__)
    end
  end
end
