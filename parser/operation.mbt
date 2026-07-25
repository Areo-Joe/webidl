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

///|
pub enum OperationName {
  OperationNameKeyword(OperationNameKeyword)
  Identifier(StringView)
}

///|
pub fn OperationName::parse(input : Tokens) -> (OperationName, Tokens)? {
  if OperationNameKeyword::parse(input) is Some((operation_name_keyword, rest)) {
    return Some(
      (OperationName::OperationNameKeyword(operation_name_keyword), rest),
    )
  }

  if input is [(@lexer.TokenType::Identifier, identifier), .. rest] {
    return Some((OperationName::Identifier(identifier), rest))
  }

  None
}

///|
pub enum OptionalOperationName {
  Some(OperationName)
  None
}

///|
pub fn OptionalOperationName::parse(
  input : Tokens,
) -> (OptionalOperationName, Tokens) {
  if OperationName::parse(input) is Some((operation_name, rest)) {
    return (OptionalOperationName::Some(operation_name), rest)
  }

  return (OptionalOperationName::None, input)
}
