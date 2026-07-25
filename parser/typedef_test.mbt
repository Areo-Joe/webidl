///|
fn parse_typedef(input : String) -> (Typedef, Tokens)? {
  Typedef::parse((try! @lexer.tokenize(input)).view())
}

///|
test "Typedef parses a plain type" {
  assert_true(
    parse_typedef("typedef DOMString Name; tail") is Some((_, [(_, "tail")])),
  )
}

///|
test "Typedef parses a type with extended attributes" {
  assert_true(
    parse_typedef("typedef [Clamp] unsigned long Count; tail")
    is Some((_, [(_, "tail")])),
  )
}

///|
test "Typedef requires its keyword, identifier, and semicolon" {
  assert_true(parse_typedef("DOMString Name;") is None)
  assert_true(parse_typedef("typedef DOMString;") is None)
  assert_true(parse_typedef("typedef DOMString Name") is None)
  assert_true(parse_typedef("typedef Unknown interface;") is None)
}
