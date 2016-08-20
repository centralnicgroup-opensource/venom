# Venom

**TODO: Add description**

## Usage


Wrappers for Poison functions that allows round-trip
encoding of non-JSON Elixir types.

The following Elixir types that aren't valid in JSON are
converted.

* tuples: `{"1", 2}` -> `["!tuple", "1", 2]`
* atoms:  `:a` -> `":a"`

Other conversions prevent injection of special types:

* tuples: `["!tuple", 1]` -> `["!tuple!", 1]`
* atoms:  `":a"` -> `"::a"`



This list of converted values will probably grow over time.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `venom` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:venom, "~> 0.1.0"}]
    end
    ```

  2. Ensure `venom` is started before your application:

    ```elixir
    def application do
      [applications: [:venom]]
    end
    ```

