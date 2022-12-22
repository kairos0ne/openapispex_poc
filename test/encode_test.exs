defmodule OpenApiSpex.EncodeTest do
  use ExUnit.Case

  alias OpenApiSpex.{
    Info,
    OpenApi,
    Components,
    Schema
  }

  test "Vendor extensions x-logo properly encoded" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0",
        extensions: %{
          "x-logo" => %{
            "url" => "https://example.com/logo.png",
            "backgroundColor" => "#FFFFFF",
            "altText" => "Example logo"
          }
        }
      },
      paths: %{}
    }

    decoded =
      OpenApiSpex.resolve_schema_modules(spec)
      |> Jason.encode!()
      |> Jason.decode!()

    assert decoded["info"]["x-logo"]["url"] == "https://example.com/logo.png"
    assert decoded["info"]["x-logo"]["backgroundColor"] == "#FFFFFF"
    assert decoded["info"]["x-logo"]["altText"] == "Example logo"

    assert is_nil(decoded["info"]["extensions"])
  end

  test "Vendor extensions x-tagGroups properly encoded" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      extensions: %{
        "x-tagGroups" => [
          %{
            "name" => "Methods",
            "tags" => [
              "Search",
              "Fetch",
              "Delete"
            ]
          }
        ]
      },
      paths: %{}
    }

    decoded =
      OpenApiSpex.resolve_schema_modules(spec)
      |> Jason.encode!()
      |> Jason.decode!()

    assert hd(decoded["x-tagGroups"])["name"] == "Methods"
    assert hd(decoded["x-tagGroups"])["tags"] == ["Search", "Fetch", "Delete"]

    assert is_nil(decoded["extensions"])
  end

  test "Example field properly encoded (MediaType, Schema)" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      paths: %{
        "/example" => %OpenApiSpex.PathItem{
          get: %OpenApiSpex.Operation{
            responses: %{
              200 => %OpenApiSpex.Response{
                description: "An example",
                content: %{
                  "application/json" => %OpenApiSpex.MediaType{
                    example: %{
                      "id" => 678,
                      "first_name" => "John",
                      "last_name" => "Doe",
                      "phone_number" => nil
                    }
                  }
                }
              }
            }
          }
        }
      },
      components: %OpenApiSpex.Components{
        schemas: %{
          "User" => %Schema{
            type: :object,
            properties: %{
              id: %Schema{type: :integer},
              first_name: %Schema{type: :string},
              last_name: %Schema{type: :string},
              phone_number: %Schema{type: :string, nullable: true}
            },
            example: %{
              "id" => 42,
              "first_name" => "Jane",
              "last_name" => "Doe",
              "phone_number" => nil
            }
          }
        }
      }
    }

    decoded =
      OpenApiSpex.resolve_schema_modules(spec)
      |> Jason.encode!()
      |> Jason.decode!()

    assert Map.has_key?(
             get_in(decoded, [
               "paths",
               "/example",
               "get",
               "responses",
               "200",
               "content",
               "application/json",
               "example"
             ]),
             "phone_number"
           )

    assert Map.has_key?(
             get_in(decoded, [
               "components",
               "schemas",
               "User",
               "example"
             ]),
             "phone_number"
           )
  end

  test "Value field from Example object properly encoded" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      paths: %{
        "/example" => %OpenApiSpex.PathItem{
          get: %OpenApiSpex.Operation{
            responses: %{
              200 => %OpenApiSpex.Response{
                description: "An example",
                content: %{
                  "application/json" => %OpenApiSpex.MediaType{
                    examples: %{
                      "John" => %OpenApiSpex.Example{
                        summary: "Its John",
                        value: %{
                          "id" => 678,
                          "first_name" => "John",
                          "last_name" => "Doe",
                          "phone_number" => nil
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    decoded =
      OpenApiSpex.resolve_schema_modules(spec)
      |> Jason.encode!()
      |> Jason.decode!()

    assert Map.has_key?(
             get_in(decoded, [
               "paths",
               "/example",
               "get",
               "responses",
               "200",
               "content",
               "application/json",
               "examples",
               "John",
               "value"
             ]),
             "phone_number"
           )
  end

  test "Required array omitted when empty" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      paths: %{},
      components: %Components{
        schemas: %{
          "contact" => %Schema{
            type: :object,
            properties: %{
              name: %Schema{type: :string},
              phone_number: %Schema{type: :string}
            },
            required: []
          },
          "address" => %Schema{
            type: :object,
            properties: %{
              street: %Schema{type: :string},
              city: %Schema{type: :string},
              post_code: %Schema{type: :string}
            },
            required: [:street]
          }
        }
      }
    }

    decoded = spec |> Jason.encode!() |> Jason.decode!()

    schemas = decoded["components"]["schemas"]
    assert %{"type" => "object"} = contact = schemas["contact"]
    refute Map.has_key?(contact, "required")

    assert %{"type" => "object", "required" => ["street"]} = schemas["address"]
  end
end
