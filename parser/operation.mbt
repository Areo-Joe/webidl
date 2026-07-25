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

///|
pub struct RegularOperation {
  type_ : Type
  operation_rest : OperationRest
}

///|
pub fn RegularOperation::parse(input : Tokens) -> (RegularOperation, Tokens)? {
  if Type::parse(input) is Some((type_, after_type)) &&
    OperationRest::parse(after_type) is Some((operation_rest, rest)) {
    return Some((RegularOperation::{ type_, operation_rest }, rest))
  }

  return None
}

///|
pub enum Special {
  Getter
  Setter
  Deleter
}

///|
pub fn Special::parse(input : Tokens) -> (Special, Tokens)? {
  match input {
    [first, .. rest] =>
      match first {
        (@lexer.TokenType::Keyword, "getter") => Some((Special::Getter, rest))
        (@lexer.TokenType::Keyword, "setter") => Some((Special::Setter, rest))
        (@lexer.TokenType::Keyword, "deleter") => Some((Special::Deleter, rest))
        _ => None
      }
    _ => None
  }
}

///|
pub struct SpecialOperation {
  special : Special
  regular_operation : RegularOperation
}

///|
pub fn SpecialOperation::parse(input : Tokens) -> (SpecialOperation, Tokens)? {
  if Special::parse(input) is Some((special, after_special)) &&
    RegularOperation::parse(after_special) is Some((regular_operation, rest)) {
    return Some((SpecialOperation::{ special, regular_operation }, rest))
  }

  None
}

///|
pub enum StringifierRest {
  Attribute(OptionalReadOnly, AttributeRest)
  Semicolon
}

///|
pub fn StringifierRest::parse(input : Tokens) -> (StringifierRest, Tokens)? {
  if OptionalReadOnly::parse(input)
    is (optional_read_only, after_optional_read_only) &&
    AttributeRest::parse(after_optional_read_only)
    is Some((attribute_rest, rest)) {
    return Some(
      (StringifierRest::Attribute(optional_read_only, attribute_rest), rest),
    )
  }

  if input is [(@lexer.TokenType::Punctuation, ";"), .. rest] {
    return Some((StringifierRest::Semicolon, rest))
  }

  None
}

///|
pub enum Operation {
  RegularOperation(RegularOperation)
  SpecialOperation(SpecialOperation)
}

///|
pub fn Operation::parse(input : Tokens) -> (Operation, Tokens)? {
  if RegularOperation::parse(input) is Some((regular_operation, rest)) {
    return Some((Operation::RegularOperation(regular_operation), rest))
  }

  if SpecialOperation::parse(input) is Some((special_operation, rest)) {
    return Some((Operation::SpecialOperation(special_operation), rest))
  }

  None
}
