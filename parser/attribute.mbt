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
