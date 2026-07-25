///|
fn union_type_tokens(input : String) -> Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "UnionType parses two members" {
  assert_true(
    UnionType::parse(union_type_tokens("(DOMString or long) tail"))
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
}

///|
test "UnionType parses additional members before its closing parenthesis" {
  assert_true(
    UnionType::parse(union_type_tokens("(DOMString or long or boolean) tail"))
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
}

///|
test "UnionType requires its closing parenthesis" {
  assert_true(UnionType::parse(union_type_tokens("(DOMString or long")) is None)
}
