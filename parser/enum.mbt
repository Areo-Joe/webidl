///|
pub struct Enum {
  identifier : StringView
  enum_value_list : EnumValueList
}

///|
pub fn Enum::parse(input : Tokens) -> (Enum, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "enum"),
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "{"),
      .. after_enum_start,
    ] &&
    EnumValueList::parse(after_enum_start)
    is Some(
      (
        enum_value_list,
        [
          (@lexer.TokenType::Punctuation, "}"),
          (@lexer.TokenType::Punctuation, ";"),
          .. rest,
        ],
      )
    ) {
    return Some((Enum::{ identifier, enum_value_list }, rest))
  }

  None
}

///|
pub struct EnumValueList {
  string : StringView
  enum_value_list_comma : EnumValueListComma
}

///|
pub fn EnumValueList::parse(input : Tokens) -> (EnumValueList, Tokens)? {
  if input is [(@lexer.TokenType::String, string), .. after_string] &&
    EnumValueListComma::parse(after_string) is (enum_value_list_comma, rest) {
    return Some((EnumValueList::{ string, enum_value_list_comma }, rest))
  }

  None
}

///|
pub enum EnumValueListComma {
  Some(EnumValueListString)
  None
}

///|
pub fn EnumValueListComma::parse(
  input : Tokens,
) -> (EnumValueListComma, Tokens) {
  if input is [(@lexer.TokenType::Punctuation, ","), .. after_comma] &&
    EnumValueListString::parse(after_comma) is (enum_value_list_string, rest) {
    return (EnumValueListComma::Some(enum_value_list_string), rest)
  }

  (EnumValueListComma::None, input)
}

///|
pub enum EnumValueListString {
  Some(StringView, EnumValueListComma)
  None
}

///|
pub fn EnumValueListString::parse(
  input : Tokens,
) -> (EnumValueListString, Tokens) {
  if input is [(@lexer.TokenType::String, string), .. after_string] &&
    EnumValueListComma::parse(after_string) is (enum_value_list_comma, rest) {
    return (EnumValueListString::Some(string, enum_value_list_comma), rest)
  }

  (EnumValueListString::None, input)
}
