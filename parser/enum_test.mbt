///|
fn parse_enum(input : String) -> (Enum, Tokens)? {
  Enum::parse((try! @lexer.tokenize(input)).view())
}

///|
test "Enum parses one value" {
  assert_true(
    parse_enum("enum Mode { \"one\" }; tail") is Some((_, [(_, "tail")])),
  )
}

///|
test "Enum parses multiple values" {
  assert_true(
    parse_enum("enum Mode { \"one\", \"two\", \"three\" }; tail")
    is Some((_, [(_, "tail")])),
  )
}

///|
test "Enum accepts the grammar's trailing comma" {
  assert_true(
    parse_enum("enum Mode { \"one\", \"two\", }; tail")
    is Some((_, [(_, "tail")])),
  )
}

///|
test "Enum rejects empty and malformed value lists" {
  assert_true(parse_enum("enum Mode {};") is None)
  assert_true(parse_enum("enum Mode { \"one\",, \"two\" };") is None)
  assert_true(parse_enum("enum Mode { one };") is None)
  assert_true(parse_enum("enum Mode { \"one\" }") is None)
  assert_true(parse_enum("enum { \"one\" };") is None)
}
