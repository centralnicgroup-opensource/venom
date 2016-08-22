# Venom

An Elixir JSON encoder that wraps around poison, allowing round tripping of Elixir data types.


## Descriptions

Some of Elixir's native types can't be converted into JSON (and back into Elixir again). This libarary uses [poison](https://github.com/devinus/poison) under the hood to create JSON, but modifies these non convertable types into a JSON-represenation.


## Usage

    data = {:tuples, :and, :atoms, :cant, :be :represented, :in, :json}
    json = Venom.encode(data)
    IO.inspect Venom.decode(json)
    # returns: {:tuples, :and, :atoms, :cant, :be :represented, :in, :json}

Venom implements all of the [poison JSON conversion functions](https://hexdocs.pm/poison/Poison.html), but wrapped with code to handle special data types.


## Encoding Details

The following Elixir types that aren't valid in JSON are converted.

* tuples: `{"1", 2}` -> `["!tuple", "1", 2]`
* atoms:  `:a` -> `":a"`

Other conversions prevent injection of special types:

* tuples: `["!tuple", 1]` -> `["!tuple!", 1]`
* atoms:  `":a"` -> `"::a"`

This list of converted values will probably grow over time.


## Missing Conversions

Non utf8 strings are not yet converted. There may be other things that need conversion; if you find something please raise an issue here.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `venom` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:venom, git: "git@github.com:iwantmyname/venom"}]
    end
    ```

  2. Ensure `venom` is started before your application:

    ```elixir
    def application do
      [applications: [:venom]]
    end
    ```

