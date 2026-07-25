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

///|
pub struct OperationRest {
  optional_operation_name : OptionalOperationName
  argument_list : ArgumentList
}

///|
pub fn OperationRest::parse(input : Tokens) -> (OperationRest, Tokens)? {
  if OptionalOperationName::parse(input)
    is (
      optional_operation_name,
      [(@lexer.TokenType::Punctuation, "("), .. after_operation_rest_start],
    ) &&
    ArgumentList::parse(after_operation_rest_start)
    is (
      argument_list,
      [
        (@lexer.TokenType::Punctuation, ")"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some(
      (OperationRest::{ optional_operation_name, argument_list }, rest),
    )
  }

  return None
}
