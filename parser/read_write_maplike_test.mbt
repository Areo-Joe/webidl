///|
fn parse_read_write_maplike(input : String) -> (ReadWriteMaplike, Tokens)? {
  ReadWriteMaplike::parse((try! @lexer.tokenize(input)).view())
}

///|
test "ReadWriteMaplike parses MaplikeRest" {
  guard parse_read_write_maplike(
      "maplike<[Clamp] unsigned long, DOMString>; tail",
    )
    is Some((_, rest)) else {
    fail("expected read-write maplike to parse")
  }
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "ReadWriteMaplike rejects other member productions" {
  assert_true(parse_read_write_maplike("setlike<DOMString>;") is None)
  assert_true(
    parse_read_write_maplike("readonly maplike<DOMString, long>;") is None,
  )
  assert_true(parse_read_write_maplike("maplike<DOMString>;") is None)
}
