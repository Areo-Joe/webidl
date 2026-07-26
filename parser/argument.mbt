///|
pub enum DefaultValue {
  ConstValue(ConstValue)
  String(StringView)
  Brackets
  Braces
  Null
  Undefined
}

///|
pub fn DefaultValue::parse(input : Tokens) -> (DefaultValue, Tokens)? {
  if ConstValue::parse(input) is Some((const_value, rest)) {
    return Some((DefaultValue::ConstValue(const_value), rest))
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

///|
pub enum Default {
  Some(DefaultValue)
  None
}

///|
pub fn Default::parse(input : Tokens) -> (Default, Tokens) {
  if input is [(@lexer.TokenType::Punctuation, "="), .. after_equal] &&
    DefaultValue::parse(after_equal) is Some((default_value, rest)) {
    return (Default::Some(default_value), rest)
  }

  (Default::None, input)
}

///|
pub enum ArgumentNameKeyword {
  Attribute
  Callback
  Const
  Constructor
  Deleter
  Dictionary
  Enum
  Getter
  Includes
  Inherit
  Interface
  Iterable
  Maplike
  Mixin
  Namespace
  Partial
  Readonly
  Required
  Setlike
  Setter
  Static
  Stringifier
  Typedef
  Unrestricted
} derive(Debug)

///|
pub fn ArgumentNameKeyword::parse(
  input : Tokens,
) -> (ArgumentNameKeyword, Tokens)? {
  match input {
    [first, .. rest] =>
      match first {
        (@lexer.TokenType::Keyword, "attribute") =>
          Some((ArgumentNameKeyword::Attribute, rest))
        (@lexer.TokenType::Keyword, "callback") =>
          Some((ArgumentNameKeyword::Callback, rest))
        (@lexer.TokenType::Keyword, "const") =>
          Some((ArgumentNameKeyword::Const, rest))
        (@lexer.TokenType::Keyword, "constructor") =>
          Some((ArgumentNameKeyword::Constructor, rest))
        (@lexer.TokenType::Keyword, "deleter") =>
          Some((ArgumentNameKeyword::Deleter, rest))
        (@lexer.TokenType::Keyword, "dictionary") =>
          Some((ArgumentNameKeyword::Dictionary, rest))
        (@lexer.TokenType::Keyword, "enum") =>
          Some((ArgumentNameKeyword::Enum, rest))
        (@lexer.TokenType::Keyword, "getter") =>
          Some((ArgumentNameKeyword::Getter, rest))
        (@lexer.TokenType::Keyword, "includes") =>
          Some((ArgumentNameKeyword::Includes, rest))
        (@lexer.TokenType::Keyword, "inherit") =>
          Some((ArgumentNameKeyword::Inherit, rest))
        (@lexer.TokenType::Keyword, "interface") =>
          Some((ArgumentNameKeyword::Interface, rest))
        (@lexer.TokenType::Keyword, "iterable") =>
          Some((ArgumentNameKeyword::Iterable, rest))
        (@lexer.TokenType::Keyword, "maplike") =>
          Some((ArgumentNameKeyword::Maplike, rest))
        (@lexer.TokenType::Keyword, "mixin") =>
          Some((ArgumentNameKeyword::Mixin, rest))
        (@lexer.TokenType::Keyword, "namespace") =>
          Some((ArgumentNameKeyword::Namespace, rest))
        (@lexer.TokenType::Keyword, "partial") =>
          Some((ArgumentNameKeyword::Partial, rest))
        (@lexer.TokenType::Keyword, "readonly") =>
          Some((ArgumentNameKeyword::Readonly, rest))
        (@lexer.TokenType::Keyword, "required") =>
          Some((ArgumentNameKeyword::Required, rest))
        (@lexer.TokenType::Keyword, "setlike") =>
          Some((ArgumentNameKeyword::Setlike, rest))
        (@lexer.TokenType::Keyword, "setter") =>
          Some((ArgumentNameKeyword::Setter, rest))
        (@lexer.TokenType::Keyword, "static") =>
          Some((ArgumentNameKeyword::Static, rest))
        (@lexer.TokenType::Keyword, "stringifier") =>
          Some((ArgumentNameKeyword::Stringifier, rest))
        (@lexer.TokenType::Keyword, "typedef") =>
          Some((ArgumentNameKeyword::Typedef, rest))
        (@lexer.TokenType::Keyword, "unrestricted") =>
          Some((ArgumentNameKeyword::Unrestricted, rest))
        _ => None
      }
    _ => None
  }
}

///|
pub enum ArgumentName {
  ArgumentNameKeyword(ArgumentNameKeyword)
  Identifier(StringView)
}

///|
pub fn ArgumentName::parse(input : Tokens) -> (ArgumentName, Tokens)? {
  if ArgumentNameKeyword::parse(input) is Some((argument_name_keyword, rest)) {
    return Some(
      (ArgumentName::ArgumentNameKeyword(argument_name_keyword), rest),
    )
  }

  if input is [(@lexer.TokenType::Identifier, identifier), .. rest] {
    return Some((ArgumentName::Identifier(identifier), rest))
  }

  return None
}

///|
pub enum Ellipsis {
  Some
  None
}

///|
pub fn Ellipsis::parse(input : Tokens) -> (Ellipsis, Tokens) {
  if input is [(@lexer.TokenType::Punctuation, "..."), .. rest] {
    return (Ellipsis::Some, rest)
  }

  (Ellipsis::None, input)
}

///|
pub enum ArgumentRest {
  Optional(TypeWithExtendedAttributes, ArgumentName, Default)
  Ellipsisable(Type, Ellipsis, ArgumentName)
}

///|
pub fn ArgumentRest::parse(input : Tokens) -> (ArgumentRest, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "optional"), .. after_optional] &&
    TypeWithExtendedAttributes::parse(after_optional)
    is Some(
      (type_with_extended_attributes, after_type_with_extended_attributes)
    ) &&
    ArgumentName::parse(after_type_with_extended_attributes)
    is Some((argument_name, after_argument_name)) &&
    Default::parse(after_argument_name) is (default, rest) {
    return Some(
      (
        ArgumentRest::Optional(
          type_with_extended_attributes, argument_name, default,
        ),
        rest,
      ),
    )
  }

  if Type::parse(input) is Some((type_, after_type)) &&
    Ellipsis::parse(after_type) is (ellipsis, after_ellipsis) &&
    ArgumentName::parse(after_ellipsis) is Some((argument_name, rest)) {
    return Some(
      (ArgumentRest::Ellipsisable(type_, ellipsis, argument_name), rest),
    )
  }

  None
}

///|
pub struct Argument {
  extended_attribute_list : ExtendedAttributeList
  argument_rest : ArgumentRest
}

///|
pub fn Argument::parse(input : Tokens) -> (Argument, Tokens)? {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    ArgumentRest::parse(after_extended_attribute_list)
    is Some((argument_rest, rest)) {
    return Some((Argument::{ extended_attribute_list, argument_rest }, rest))
  }

  None
}

///|
pub enum Arguments {
  Some(Argument, Arguments)
  None
}

///|
pub fn Arguments::iter(self : Self) -> Iter[Argument] {
  let mut target = self

  Iter::new(() => {
    match target {
      Some(current_argument, rest) => {
        target = rest

        Some(current_argument)
      }
      None => None
    }
  })
}

///|
pub fn Arguments::parse(input : Tokens) -> (Arguments, Tokens) {
  if input is [(@lexer.TokenType::Punctuation, ","), .. after_comma] &&
    Argument::parse(after_comma) is Some((argument, after_argument)) &&
    Arguments::parse(after_argument) is (arguments, rest) {
    return (Arguments::Some(argument, arguments), rest)
  }

  (Arguments::None, input)
}

///|
pub enum ArgumentList {
  Some(Argument, Arguments)
  None
}

///|
pub fn ArgumentList::iter(self : Self) -> Iter[Argument] {
  match self {
    Some(first_argument, rest) =>
      Iter::singleton(first_argument).concat(rest.iter())
    None => Iter::empty()
  }
}

///|
pub fn ArgumentList::parse(input : Tokens) -> (ArgumentList, Tokens) {
  if Argument::parse(input) is Some((argument, after_argument)) &&
    Arguments::parse(after_argument) is (arguments, rest) {
    return (ArgumentList::Some(argument, arguments), rest)
  }

  return (ArgumentList::None, input)
}

///|
pub enum BooleanLiteral {
  True
  False
}

///|
pub fn BooleanLiteral::parse(input : Tokens) -> (BooleanLiteral, Tokens)? {
  match input {
    [first, .. rest] =>
      match first {
        (@lexer.TokenType::Keyword, "true") =>
          Some((BooleanLiteral::True, rest))
        (@lexer.TokenType::Keyword, "false") =>
          Some((BooleanLiteral::False, rest))
        _ => None
      }
    _ => None
  }
}

///|
pub enum FloatLiteral {
  Decimal(StringView)
  NegativeInfinity
  Infinity
  NaN
}

///|
pub fn FloatLiteral::parse(input : Tokens) -> (FloatLiteral, Tokens)? {
  if input is [(@lexer.TokenType::Decimal, decimal), .. rest] {
    return Some((FloatLiteral::Decimal(decimal), rest))
  }

  if input is [(@lexer.TokenType::Keyword, "-Infinity"), .. rest] {
    return Some((FloatLiteral::NegativeInfinity, rest))
  }

  if input is [(@lexer.TokenType::Keyword, "Infinity"), .. rest] {
    return Some((FloatLiteral::Infinity, rest))
  }

  if input is [(@lexer.TokenType::Keyword, "NaN"), .. rest] {
    return Some((FloatLiteral::NaN, rest))
  }

  None
}

///|
pub enum ConstValue {
  BooleanLiteral(BooleanLiteral)
  FloatLiteral(FloatLiteral)
  Integer(StringView)
}

///|
pub fn ConstValue::parse(input : Tokens) -> (ConstValue, Tokens)? {
  if BooleanLiteral::parse(input) is Some((boolean_literal, rest)) {
    return Some((ConstValue::BooleanLiteral(boolean_literal), rest))
  }

  if FloatLiteral::parse(input) is Some((float_literal, rest)) {
    return Some((ConstValue::FloatLiteral(float_literal), rest))
  }

  if input is [(@lexer.TokenType::Integer, integer), .. rest] {
    return Some((ConstValue::Integer(integer), rest))
  }

  None
}
