///|
pub enum DefaultValue {
  ConstValue(ConstType)
  String(StringView)
  Brackets
  Braces
  Null
  Undefined
}

///|
pub fn DefaultValue::parse(input : Tokens) -> (DefaultValue, Tokens)? {
  if ConstType::parse(input) is Some((const_type, rest)) {
    return Some((DefaultValue::ConstValue(const_type), rest))
  }

  if input is [(@lexer.TokenType::String, string), .. rest] {
    return Some((DefaultValue::String(string), rest))
  }

  if input
    is [
      (@lexer.TokenType::Punctuation, "{"),
      (@lexer.TokenType::Punctuation, "}"),
      .. rest,
    ] {
    return Some((DefaultValue::Braces, rest))
  }

  if input
    is [
      (@lexer.TokenType::Punctuation, "["),
      (@lexer.TokenType::Punctuation, "]"),
      .. rest,
    ] {
    return Some((DefaultValue::Brackets, rest))
  }

  if input is [(@lexer.TokenType::Keyword, "null"), .. rest] {
    return Some((DefaultValue::Null, rest))
  }

  if input is [(@lexer.TokenType::Keyword, "undefined"), .. rest] {
    return Some((DefaultValue::Undefined, rest))
  }

  None
}
