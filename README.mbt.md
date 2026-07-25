# webidl

A Web IDL parser for MoonBit.

The parser follows the Web IDL grammar and produces a typed syntax tree rooted
at `Definitions`.

## Usage

```mbt check
///|
test "parse Web IDL" {
  let definitions = @webidl.parse(
    (
      #|[Exposed=Window]
      #|interface Example {
      #|  readonly attribute DOMString name;
      #|};
    ),
  )
  ignore(definitions)
}
```

`parse` consumes the complete input and raises when the input is invalid or
contains trailing tokens.

Lower-level lexer and grammar-production APIs are available in the `lexer` and
`parser` packages.

## Validation

The test suite includes the Web IDL files published by the
[Web Platform Tests project](https://wpt.live/interfaces/).

Run the tests with:

```sh
moon test
```

## License

MIT
