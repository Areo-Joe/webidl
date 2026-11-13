///|
fn parse_maplike_rest(input : String) -> (@parser.MaplikeRest, @parser.Tokens)? {
  @parser.MaplikeRest::parse((try! @lexer.tokenize(input)).view())
}

///|
test "MaplikeRest parses its key and value types" {
  guard parse_maplike_rest("maplike<DOMString, [Clamp] unsigned long>; tail")
    is Some((_, rest)) else {
    fail("expected MaplikeRest to parse")
  }
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "MaplikeRest requires two types and its terminator" {
  assert_true(parse_maplike_rest("maplike<DOMString>;") is None)
  assert_true(parse_maplike_rest("maplike<DOMString, long>") is None)
  assert_true(parse_maplike_rest("setlike<DOMString, long>;") is None)
}
