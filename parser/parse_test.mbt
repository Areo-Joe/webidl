///|
fn parse_source(input : String) -> (@parser.Definitions, @parser.Tokens) {
  @parser.parse((try! @lexer.tokenize(input)).exact_view())
}

///|
test "parse consumes a complete fragment with extended attributes" {
  assert_true(
    parse_source(
      "[Exposed=Window] interface Example {}; [Clamp] typedef long Count;",
    )
    is (
      @parser.Definitions::Some(
        @parser.ExtendedAttributeList::Some(_, _),
        @parser.Definition::CallbackOrInterfaceOrMixin(_),
        @parser.Definitions::Some(
          @parser.ExtendedAttributeList::Some(_, _),
          @parser.Definition::Typedef(_),
          @parser.Definitions::None
        )
      ),
      [],
    ),
  )
}

///|
test "parse accepts the empty fragment" {
  assert_true(parse_source("") is (@parser.Definitions::None, []))
}

///|
test "parse preserves trailing input" {
  assert_true(
    parse_source("interface Example {}; trailing")
    is (
      @parser.Definitions::Some(_, _, @parser.Definitions::None),
      [(@lexer.TokenType::Identifier, "trailing")],
    ),
  )
}

///|
test "parse leaves malformed definitions and extended attributes unconsumed" {
  assert_true(
    parse_source("interface Example {}")
    is (
      @parser.Definitions::None,
      [(@lexer.TokenType::Keyword, "interface"), ..],
    ),
  )
  assert_true(
    parse_source("[Exposed] interface Example {}")
    is (@parser.Definitions::None, [(@lexer.TokenType::Punctuation, "["), ..]),
  )
  assert_true(
    parse_source("[Exposed,] interface Example {};")
    is (@parser.Definitions::None, [(@lexer.TokenType::Punctuation, "["), ..]),
  )
}
