///|
pub enum AttributeNameKeyword {
  Required
}

///|
pub fn AttributeNameKeyword::parse(
  input : Tokens,
) -> (AttributeNameKeyword, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "required"), .. rest] {
    return Some((AttributeNameKeyword::Required, rest))
  }

  None
}
