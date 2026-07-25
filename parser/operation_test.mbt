///|
fn operation_tokens(input : String) -> Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "OperationNameKeyword parses lowercase includes" {
  assert_true(
    OperationNameKeyword::parse(operation_tokens("includes tail"))
    is Some(
      (OperationNameKeyword::Includes, [(@lexer.TokenType::Identifier, "tail")])
    ),
  )
}

///|
test "RegularOperation accepts includes as its operation name" {
  assert_true(
    RegularOperation::parse(operation_tokens("undefined includes(); tail"))
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
}
