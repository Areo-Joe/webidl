///|
fn parse_setlike_rest(input : String) -> (@parser.SetlikeRest, @parser.Tokens)? {
  @parser.SetlikeRest::parse((try! @lexer.tokenize(input)).view())
}

///|
test "SetlikeRest parses its element type" {
  guard parse_setlike_rest("setlike<[Clamp] unsigned long>; tail")
    is Some((_, rest)) else {
    fail("expected SetlikeRest to parse")
  }
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "SetlikeRest requires one type and its terminator" {
  assert_true(parse_setlike_rest("setlike<>;") is None)
  assert_true(parse_setlike_rest("setlike<DOMString, long>;") is None)
  assert_true(parse_setlike_rest("setlike<DOMString>") is None)
  assert_true(parse_setlike_rest("maplike<DOMString>;") is None)
}
