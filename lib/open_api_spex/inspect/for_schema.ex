defimpl Inspect, for: OpenApiSpex.Schema do
  import Inspect.Algebra

  # def inspect(parameter, opts) do
  #   concat(["OpenApiSpex.Schema.new(", Inspect.Map.inspect(parameter, opts), ")"])
  # end

  def inspect(parameter, opts) do
    map =
      parameter
      |> Map.from_struct()
      |> Enum.filter(fn
        {_key, nil} -> false
        {_key, _value} -> true
      end)
      |> Map.new()
      |> to_doc(opts)
      |> String.replace(~r/%/, "")


    concat(["%OpenApiSpex.Schema", map])
  end
end
