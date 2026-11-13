///|
fn operation_tokens(input : String) -> @parser.Tokens {
  (try! @lexer.tokenize(input)).exact_view()
}

///|
test "OperationNameKeyword parses lowercase includes" {
  assert_true(
    @parser.OperationNameKeyword::parse(operation_tokens("includes tail"))
    is Some(
      (
        @parser.OperationNameKeyword::Includes,
        [(@lexer.TokenType::Identifier, "tail")],
      )
    ),
  )
}

///|
test "RegularOperation accepts includes as its operation name" {
  assert_true(
    @parser.RegularOperation::parse(
      operation_tokens("undefined includes(); tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
}
