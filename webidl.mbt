///|
pub fn parse(source : StringView) -> @parser.Definitions raise {
  let tokens = @lexer.tokenize(source)
  match @parser.parse(tokens.exact_view()) {
    (definitions, []) => definitions
    _ => fail("invalid Web IDL")
  }
}
