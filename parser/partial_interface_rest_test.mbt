///|
fn parse_partial_interface_rest(
  input : String,
) -> (PartialInterfaceRest, Tokens)? {
  PartialInterfaceRest::parse((try! @lexer.tokenize(input)).view())
}

///|
test "PartialInterfaceRest parses an empty body" {
  guard parse_partial_interface_rest("Example {}; tail") is Some((_, rest)) else {
    fail("expected empty partial interface rest to parse")
  }
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "PartialInterfaceRest parses recursive attributed members" {
  guard parse_partial_interface_rest(
      "Example { [Clamp] attribute DOMString name; const long value = 1; }; tail",
    )
    is Some((_, rest)) else {
    fail("expected populated partial interface rest to parse")
  }
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "PartialInterfaceRest requires its identifier and delimiters" {
  assert_true(parse_partial_interface_rest("interface {};") is None)
  assert_true(
    parse_partial_interface_rest("Example { const long value = 1;") is None,
  )
  assert_true(parse_partial_interface_rest("Example {}") is None)
}
