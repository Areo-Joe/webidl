///|
fn parse_source(input : String) -> (Definitions, Tokens) {
  parse((try! @lexer.tokenize(input)).view())
}

///|
test "parse consumes a complete fragment with extended attributes" {
  assert_true(
    parse_source(
      "[Exposed=Window] interface Example {}; [Clamp] typedef long Count;",
    )
    is (
      Definitions::Some(
        ExtendedAttributeList::Some(_, _),
        Definition::CallbackOrInterfaceOrMixin(_),
        Definitions::Some(
          ExtendedAttributeList::Some(_, _),
          Definition::Typedef(_),
          Definitions::None
        )
      ),
      [],
    ),
  )
}

///|
test "parse accepts the empty fragment" {
  assert_true(parse_source("") is (Definitions::None, []))
}

///|
test "parse preserves trailing input" {
  assert_true(
    parse_source("interface Example {}; trailing")
    is (
      Definitions::Some(_, _, Definitions::None),
      [(@lexer.TokenType::Identifier, "trailing")],
    ),
  )
}

///|
test "parse leaves malformed definitions and extended attributes unconsumed" {
  assert_true(
    parse_source("interface Example {}")
    is (Definitions::None, [(@lexer.TokenType::Keyword, "interface"), ..]),
  )
  assert_true(
    parse_source("[Exposed] interface Example {}")
    is (Definitions::None, [(@lexer.TokenType::Punctuation, "["), ..]),
  )
  assert_true(
    parse_source("[Exposed,] interface Example {};")
    is (Definitions::None, [(@lexer.TokenType::Punctuation, "["), ..]),
  )
}
