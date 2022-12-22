defimpl Inspect, for: OpenApiSpex.Schema do
  import Inspect.Algebra

  # def inspect(parameter, opts) do
  #   concat(["OpenApiSpex.Schema.new(", Inspect.Map.inspect(parameter, opts), ")"])
  # end

  def inspect(schema, opts) do
    concat([
      "OpenApiSpex.Schema.new(",
      inspect(schema.__struct__),
      ", ",
      Inspect.Map.inspect(schema, opts),
      ")"
    ])
  end
end
