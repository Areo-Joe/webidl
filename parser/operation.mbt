///|
pub enum OperationNameKeyword {
  Includes
}

///|
pub fn OperationNameKeyword::parse(
  input : Tokens,
) -> (OperationNameKeyword, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "Includes"), .. rest] {
    return Some((OperationNameKeyword::Includes, rest))
  }

  None
}
