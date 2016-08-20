defmodule Venom do
  @moduledoc """
    Wrappers for Poison functions that allows round-trip
    encoding of non-JSON Elixir types.

    The fololowing Elixir types that aren't valid in JSON are
    converted.

     * tuples: `{"1", 2}` -> `["!tuple", "1", 2]`
     * atoms:  `:a` -> `":a"`

    Other conversions prevent injection of special types:

     * tuples: `["!tuple", 1]` -> `["!tuple!", 1]`
     * atoms:  `":a"` -> `"::a"`

    This list of converted values will probably grow over time.
  """

  # REVIEW: should we convert non utf8 binaries to storable strings as well?
  # REVIEW: %{1 => "a"} isn't allowed by Poison and could be escaped

  def decode(iodata, opts \\ []) do
    case Poison.decode(iodata, opts) do
      {:ok, value} -> {:ok, recursively_unescape_types(value)}
      err -> err
    end
  end
  def decode!(iodata, opts \\ []),
    do: Poison.decode!(iodata, opts) |> recursively_unescape_types

  def encode(value, opts \\ []),
    do: Poison.encode(recursively_escape_types(value), opts)
  def encode!(value, opts \\ []),
    do: Poison.encode!(recursively_escape_types(value), opts)

  def encode_to_iodata(value, opts \\ []),
    do: Poison.encode_to_iodata(recursively_escape_types(value), opts)
  def encode_to_iodata!(value, opts \\ []),
    do: Poison.encode_to_iodata!(recursively_escape_types(value), opts)

  def test do
    m1 = %{
      a: {32, :A},
      b: [a: :B, b: :B],
      c: %{"1" => "a", b: ":c"},
      d: %{dd: [ee: 1]},
    }
    IO.puts []
    IO.inspect m1
    IO.puts []
    IO.inspect (m1
                |> Venom.encode!
                |> Venom.decode!)
    IO.puts []
    IO.puts Venom.encode!(m1, pretty: true)


    m2 = %{
      a: {1, 2},
      b: ["!tuple", 1, 2],
      c: ["!tuple!", 1, 2],
    }
    IO.puts []
    IO.inspect m2
    IO.inspect (m2
                |> Venom.encode!
                |> Venom.decode!)
    IO.puts Venom.encode!(m2)

    m3 = [:a, ":a", "::a"]
    IO.puts []
    IO.inspect m3
    IO.inspect (m3
            |> Venom.encode!
            |> Venom.decode!)
    IO.puts Venom.encode!(m3)

    nil
  end

  @doc """
  Recursively walk the tree of an Elixir object, returning
  a copy with all non JSON-compatible Elixir types escaped.
  """

  # walking + conversions

  defp recursively_escape_types(elem) when is_tuple(elem) do
    list = Tuple.to_list(elem)
    ["!tuple"] ++ recursively_escape_types(list)
  end
  defp recursively_escape_types([<<"!tuple", string::binary>>| tl]) do
    ["!tuple!" <> string] ++ recursively_escape_types(tl)
  end

  defp recursively_escape_types(elem) when is_atom(elem), do: ":" <> Atom.to_string(elem)
  defp recursively_escape_types(<<":", string::binary>>), do: "::" <> string

  # walking

  defp recursively_escape_types(elem) when is_map(elem) do
    elem
    |> Enum.map(fn {k, v} -> {recursively_escape_types(k), recursively_escape_types(v)} end)
    |> Enum.into(%{})
  end

  defp recursively_escape_types(elem) when is_list(elem) do
    elem |> Enum.map(&recursively_escape_types/1)
  end

  defp recursively_escape_types(elem), do: elem


  @doc """
  Recursively walk an Elixir object's tree, returning a
  copy with the Elixir types escaped by
  `recursively_escape_types/1` converted back to their
  original values.
  """

  # walking + conversions

  defp recursively_unescape_types([<<"!tuple!", string::binary>>| tl]) do
    ["!tuple" <> string] ++ recursively_unescape_types(tl)
  end
  defp recursively_unescape_types(["!tuple"| tl]) do
    recursively_unescape_types(tl) |> List.to_tuple
  end

  defp recursively_unescape_types(<<"::", string::binary>>), do: ":" <> string
  defp recursively_unescape_types(<<":", string::binary>>), do: String.to_atom(string)

  # walking

  defp recursively_unescape_types(elem) when is_map(elem) do
    elem
    |> Enum.map(fn {k, v} -> {recursively_unescape_types(k), recursively_unescape_types(v)} end)
    |> Enum.into(%{})
  end

  defp recursively_unescape_types(elem) when is_list(elem) do
    elem |> Enum.map(&recursively_unescape_types/1)
  end

  defp recursively_unescape_types(elem), do: elem
end

# TODO: write test for nested and top-level conversions:
#  for X <- [List, Map, Tuple, Atom, Number, String ] do
#    nested X converted
#    top-level X converted

# TODO: write test for maps:
#    keys get converted
#    maps get converted

# TODO: write generic test for a crazy tree:
#  m1 = %{ a: {32, :A}, b: [a: :B, b: :B], c: %{"1" => "a", b: ":c"}, d: %{dd: [ee: 1]}, }

# TODO: write test for atom escaping:
#  :atom -> ":atom"
#  ":atom" -> "::atom"
#  "::atom" -> ":::atom"

# TODO: write test for tuple escaping:
#  {1, 2} -> ["!tuple", 1, 2]
#  ["!tuple", 1, 2] -> ["!tuple!", 1, 2]
#  ["!tuple!", 1, 2] -> ["!tuple!!", 1, 2]

