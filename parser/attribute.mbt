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

///|
pub enum AttributeName {
  AttributeNameKeyword(AttributeNameKeyword)
  Identifier(StringView)
}

///|
pub fn AttributeName::parse(input : Tokens) -> (AttributeName, Tokens)? {
  if AttributeNameKeyword::parse(input) is Some((attribute_name_keyword, rest)) {
    return Some(
      (AttributeName::AttributeNameKeyword(attribute_name_keyword), rest),
    )
  }

  if input is [(@lexer.TokenType::Identifier, identifier), .. rest] {
    return Some((AttributeName::Identifier(identifier), rest))
  }

  None
}

///|
pub struct AttributeRest {
  type_with_extended_attributes : TypeWithExtendedAttributes
  attribute_name : AttributeName
}

///|
pub fn AttributeRest::parse(input : Tokens) -> (AttributeRest, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "attribute"), .. after_attribute] &&
    TypeWithExtendedAttributes::parse(after_attribute)
    is Some(
      (type_with_extended_attributes, after_type_with_extended_attributes)
    ) &&
    AttributeName::parse(after_type_with_extended_attributes)
    is Some((attribute_name, [(@lexer.TokenType::Punctuation, ";"), .. rest])) {
    return Some(
      (AttributeRest::{ type_with_extended_attributes, attribute_name }, rest),
    )
  }

  return None
}
