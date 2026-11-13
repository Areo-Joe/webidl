///|
fn parse_includes_statement(
  input : String,
) -> (@parser.IncludesStatement, @parser.Tokens)? {
  @parser.IncludesStatement::parse((try! @lexer.tokenize(input)).exact_view())
}

///|
test "IncludesStatement parses identifiers and preserves trailing tokens" {
  assert_true(
    parse_includes_statement("Example includes Shared; tail")
    is Some((_, [(_, "tail")])),
  )
}

///|
test "IncludesStatement requires its keyword, identifiers, and semicolon" {
  assert_true(parse_includes_statement("Example Shared;") is None)
  assert_true(parse_includes_statement("includes Shared;") is None)
  assert_true(parse_includes_statement("Example includes;") is None)
  assert_true(parse_includes_statement("Example includes Shared") is None)
  assert_true(parse_includes_statement("interface includes Shared;") is None)
}
