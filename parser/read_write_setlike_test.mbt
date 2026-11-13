///|
fn parse_read_write_setlike(
  input : String,
) -> (@parser.ReadWriteSetlike, @parser.Tokens)? {
  @parser.ReadWriteSetlike::parse((try! @lexer.tokenize(input)).exact_view())
}

///|
test "ReadWriteSetlike parses SetlikeRest" {
  guard parse_read_write_setlike("setlike<[Clamp] unsigned long>; tail")
    is Some((_, rest)) else {
    fail("expected read-write setlike to parse")
  }
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "ReadWriteSetlike rejects other member productions" {
  assert_true(parse_read_write_setlike("maplike<DOMString, long>;") is None)
  assert_true(parse_read_write_setlike("readonly setlike<DOMString>;") is None)
  assert_true(parse_read_write_setlike("setlike<>;") is None)
}
