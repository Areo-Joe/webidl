///|
fn parse_partial_dictionary(input : String) -> (PartialDictionary, Tokens)? {
  PartialDictionary::parse((try! @lexer.tokenize(input)).view())
}

///|
test "PartialDictionary parses an empty body" {
  assert_true(
    parse_partial_dictionary("dictionary Options {}; tail")
    is Some((_, [(_, "tail")])),
  )
}

///|
test "PartialDictionary parses recursive attributed members" {
  assert_true(
    parse_partial_dictionary(
      "dictionary Options { [Clamp] required unsigned long count; DOMString label = \"default\"; }; tail",
    )
    is Some((_, [(_, "tail")])),
  )
}

///|
test "PartialDictionary rejects inheritance and malformed input" {
  assert_true(parse_partial_dictionary("dictionary Options : Base {};") is None)
  assert_true(
    parse_partial_dictionary("dictionary Options { required long count };")
    is None,
  )
  assert_true(parse_partial_dictionary("dictionary Options {}") is None)
  assert_true(parse_partial_dictionary("dictionary {};") is None)
}
