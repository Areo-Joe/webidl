///|
pub enum ExtendedAttributeList {
  Some(ExtendedAttribute, ExtendedAttributes)
  None
}

///|
pub fn ExtendedAttributeList::iter(self : Self) -> Iter[ExtendedAttribute] {
  match self {
    Some(first_attribute, rest) =>
      Iter::singleton(first_attribute).concat(rest.iter())
    None => Iter::empty()
  }
}

///|
pub fn ExtendedAttributeList::parse(
  input : Tokens,
) -> (ExtendedAttributeList, Tokens) {
  match input {
    [(@lexer.TokenType::Punctuation, "["), .. after_open_bracket] => {
      guard ExtendedAttribute::parse(after_open_bracket)
        is Some((extended_attribute, after_extended_attribute)) else {
        (ExtendedAttributeList::None, input)
      }

      let (extended_attributes, after_extended_attributes) = ExtendedAttributes::parse(
        after_extended_attribute,
      )

      guard after_extended_attributes
        is [(@lexer.TokenType::Punctuation, "]"), .. after_close_bracket] else {
        (ExtendedAttributeList::None, input)
      }

      (
        ExtendedAttributeList::Some(extended_attribute, extended_attributes),
        after_close_bracket,
      )
    }
    _ => (ExtendedAttributeList::None, input)
  }
}

///|
pub enum ExtendedAttributes {
  Some(ExtendedAttribute, ExtendedAttributes)
  None
}

///|
pub fn ExtendedAttributes::iter(self : Self) -> Iter[ExtendedAttribute] {
  let mut target = self

  Iter::new(() => {
    match target {
      Some(current_attribute, rest) => {
        target = rest

        Some(current_attribute)
      }
      None => None
    }
  })
}

///|
pub fn ExtendedAttributes::parse(
  input : Tokens,
) -> (ExtendedAttributes, Tokens) {
  match input {
    [(@lexer.TokenType::Punctuation, ","), .. after_comma] => {
      guard ExtendedAttribute::parse(after_comma)
        is Some((extended_attribute, after_extended_attribute)) else {
        (ExtendedAttributes::None, input)
      }

      let (extended_attributes, rest) = ExtendedAttributes::parse(
        after_extended_attribute,
      )

      (ExtendedAttributes::Some(extended_attribute, extended_attributes), rest)
    }
    _ => (ExtendedAttributes::None, input)
  }
}

///|
/// The ten forms an extended attribute may take, per WebIDL § 2.14.
///
/// The `ExtendedAttribute` production in the grammar matches nearly any token
/// sequence; this parser instead accepts only the forms the specification
/// defines, so an extended attribute using any other shape is rejected.
pub enum ExtendedAttribute {
  NoArgs(ExtendedAttributeNoArgs)
  ArgList(ExtendedAttributeArgList)
  NamedArgList(ExtendedAttributeNamedArgList)
  Ident(ExtendedAttributeIdent)
  String(ExtendedAttributeString)
  Integer(ExtendedAttributeInteger)
  Decimal(ExtendedAttributeDecimal)
  IntegerList(ExtendedAttributeIntegerList)
  IdentList(ExtendedAttributeIdentList)
  Wildcard(ExtendedAttributeWildcard)
}

///|
/// Forms are tried from the most specific to the most general, because several
/// of them share a prefix: `Attr=Value(...)` also starts like `Attr=Value`, and
/// `Attr(...)` also starts like a bare `Attr`.
pub fn ExtendedAttribute::parse(input : Tokens) -> (ExtendedAttribute, Tokens)? {
  if ExtendedAttributeNamedArgList::parse(input) is Some((form, rest)) {
    return Some((ExtendedAttribute::NamedArgList(form), rest))
  }

  if ExtendedAttributeArgList::parse(input) is Some((form, rest)) {
    return Some((ExtendedAttribute::ArgList(form), rest))
  }

  if ExtendedAttributeIdentList::parse(input) is Some((form, rest)) {
    return Some((ExtendedAttribute::IdentList(form), rest))
  }

  if ExtendedAttributeIntegerList::parse(input) is Some((form, rest)) {
    return Some((ExtendedAttribute::IntegerList(form), rest))
  }

  if ExtendedAttributeWildcard::parse(input) is Some((form, rest)) {
    return Some((ExtendedAttribute::Wildcard(form), rest))
  }

  if ExtendedAttributeIdent::parse(input) is Some((form, rest)) {
    return Some((ExtendedAttribute::Ident(form), rest))
  }

  if ExtendedAttributeString::parse(input) is Some((form, rest)) {
    return Some((ExtendedAttribute::String(form), rest))
  }

  if ExtendedAttributeInteger::parse(input) is Some((form, rest)) {
    return Some((ExtendedAttribute::Integer(form), rest))
  }

  if ExtendedAttributeDecimal::parse(input) is Some((form, rest)) {
    return Some((ExtendedAttribute::Decimal(form), rest))
  }

  if ExtendedAttributeNoArgs::parse(input) is Some((form, rest)) {
    return Some((ExtendedAttribute::NoArgs(form), rest))
  }

  None
}

///|
pub enum ExtendedAttributeInner {
  Parentheses(ExtendedAttributeInner, ExtendedAttributeInner)
  Brackets(ExtendedAttributeInner, ExtendedAttributeInner)
  Braces(ExtendedAttributeInner, ExtendedAttributeInner)
  OtherOrComma(OtherOrComma, ExtendedAttributeInner)
  None
} derive(Debug)

///|
pub fn ExtendedAttributeInner::parse(
  input : Tokens,
) -> (ExtendedAttributeInner, Tokens) {
  fn parse_other_or_comma(input : Tokens) -> (ExtendedAttributeInner, Tokens) {
    guard OtherOrComma::parse(input)
      is Some((other_or_comma, after_other_or_comma)) else {
      (ExtendedAttributeInner::None, input)
    }
    let (extended_attribute_inner, rest) = ExtendedAttributeInner::parse(
      after_other_or_comma,
    )
    (
      ExtendedAttributeInner::OtherOrComma(
        other_or_comma, extended_attribute_inner,
      ),
      rest,
    )
  }

  match input {
    [first, .. rest] =>
      match first {
        (@lexer.TokenType::Punctuation, "(") => {
          let (inner_extended_attribute_inner, after_inner) = ExtendedAttributeInner::parse(
            rest,
          )

          guard after_inner
            is [(@lexer.TokenType::Punctuation, ")"), .. after_parentheses] else {
            (ExtendedAttributeInner::None, input)
          }

          let (outer_extended_attribute_inner, after_outer) = ExtendedAttributeInner::parse(
            after_parentheses,
          )

          (
            ExtendedAttributeInner::Parentheses(
              inner_extended_attribute_inner, outer_extended_attribute_inner,
            ),
            after_outer,
          )
        }
        (@lexer.TokenType::Punctuation, "{") => {
          let (inner_extended_attribute_inner, after_inner) = ExtendedAttributeInner::parse(
            rest,
          )

          guard after_inner
            is [(@lexer.TokenType::Punctuation, "}"), .. after_braces] else {
            (ExtendedAttributeInner::None, input)
          }

          let (outer_extended_attribute_inner, after_outer) = ExtendedAttributeInner::parse(
            after_braces,
          )

          (
            ExtendedAttributeInner::Braces(
              inner_extended_attribute_inner, outer_extended_attribute_inner,
            ),
            after_outer,
          )
        }
        (@lexer.TokenType::Punctuation, "[") => {
          let (inner_extended_attribute_inner, after_inner) = ExtendedAttributeInner::parse(
            rest,
          )

          guard after_inner
            is [(@lexer.TokenType::Punctuation, "]"), .. after_brackets] else {
            (ExtendedAttributeInner::None, input)
          }

          let (outer_extended_attribute_inner, after_outer) = ExtendedAttributeInner::parse(
            after_brackets,
          )

          (
            ExtendedAttributeInner::Brackets(
              inner_extended_attribute_inner, outer_extended_attribute_inner,
            ),
            after_outer,
          )
        }
        _ => parse_other_or_comma(input)
      }
    _ => parse_other_or_comma(input)
  }
}

///|
pub enum OtherOrComma {
  Other(Other)
  Comma
} derive(Debug)

///|
pub fn OtherOrComma::parse(input : Tokens) -> (OtherOrComma, Tokens)? {
  match input {
    [first, .. rest] =>
      match first {
        (@lexer.TokenType::Punctuation, ",") =>
          Some((OtherOrComma::Comma, rest))
        _ => {
          guard Other::parse(input) is Some((other, rest)) else { None }
          Some((OtherOrComma::Other(other), rest))
        }
      }
    _ => None
  }
}

///|
pub enum Other {
  Integer(StringView)
  Decimal(StringView)
  Identifier(StringView)
  String(StringView)
  Other(StringView)
  Minus
  NegativeInfinity
  Dot
  Ellipsis
  Colon
  Semicolon
  LessThan
  Equal
  GreaterThan
  QuestionMark
  Asterisk
  ByteString
  DOMString
  FrozenArray
  Infinity
  NaN
  ObservableArray
  Promise
  USVString
  Any
  Bigint
  Boolean
  Byte
  Double
  False
  Float
  Long
  Null
  Object
  Octet
  Or
  Optional
  Record
  Sequence
  Short
  Symbol
  True
  Unsigned
  Undefined
  ArgumentNameKeyword(ArgumentNameKeyword)
  BufferRelatedType(BufferRelatedType)
} derive(Debug)

///|
pub fn Other::parse(input : Tokens) -> (Other, Tokens)? {
  match input {
    [first, .. rest] =>
      match first {
        (@lexer.TokenType::Integer, inner) =>
          Some((Other::Integer(inner), rest))
        (@lexer.TokenType::Decimal, inner) =>
          Some((Other::Decimal(inner), rest))
        (@lexer.TokenType::Identifier, inner) =>
          Some((Other::Identifier(inner), rest))
        (@lexer.TokenType::Other, inner) => Some((Other::Other(inner), rest))
        (@lexer.TokenType::String, inner) => Some((Other::String(inner), rest))
        (@lexer.TokenType::Punctuation, "-") => Some((Other::Minus, rest))
        (@lexer.TokenType::Keyword, "-Infinity") =>
          Some((Other::NegativeInfinity, rest))
        (@lexer.TokenType::Punctuation, ".") => Some((Other::Dot, rest))
        (@lexer.TokenType::Punctuation, "...") => Some((Other::Ellipsis, rest))
        (@lexer.TokenType::Punctuation, ":") => Some((Other::Colon, rest))
        (@lexer.TokenType::Punctuation, ";") => Some((Other::Semicolon, rest))
        (@lexer.TokenType::Punctuation, "<") => Some((Other::LessThan, rest))
        (@lexer.TokenType::Punctuation, "=") => Some((Other::Equal, rest))
        (@lexer.TokenType::Punctuation, ">") => Some((Other::GreaterThan, rest))
        (@lexer.TokenType::Punctuation, "?") =>
          Some((Other::QuestionMark, rest))
        (@lexer.TokenType::Punctuation, "*") => Some((Other::Asterisk, rest))
        (@lexer.TokenType::Keyword, "ByteString") =>
          Some((Other::ByteString, rest))
        (@lexer.TokenType::Keyword, "DOMString") =>
          Some((Other::DOMString, rest))
        (@lexer.TokenType::Keyword, "FrozenArray") =>
          Some((Other::FrozenArray, rest))
        (@lexer.TokenType::Keyword, "Infinity") => Some((Other::Infinity, rest))
        (@lexer.TokenType::Keyword, "NaN") => Some((Other::NaN, rest))
        (@lexer.TokenType::Keyword, "ObservableArray") =>
          Some((Other::ObservableArray, rest))
        (@lexer.TokenType::Keyword, "Promise") => Some((Other::Promise, rest))
        (@lexer.TokenType::Keyword, "USVString") =>
          Some((Other::USVString, rest))
        (@lexer.TokenType::Keyword, "any") => Some((Other::Any, rest))
        (@lexer.TokenType::Keyword, "bigint") => Some((Other::Bigint, rest))
        (@lexer.TokenType::Keyword, "boolean") => Some((Other::Boolean, rest))
        (@lexer.TokenType::Keyword, "byte") => Some((Other::Byte, rest))
        (@lexer.TokenType::Keyword, "double") => Some((Other::Double, rest))
        (@lexer.TokenType::Keyword, "false") => Some((Other::False, rest))
        (@lexer.TokenType::Keyword, "float") => Some((Other::Float, rest))
        (@lexer.TokenType::Keyword, "long") => Some((Other::Long, rest))
        (@lexer.TokenType::Keyword, "null") => Some((Other::Null, rest))
        (@lexer.TokenType::Keyword, "object") => Some((Other::Object, rest))
        (@lexer.TokenType::Keyword, "octet") => Some((Other::Octet, rest))
        (@lexer.TokenType::Keyword, "or") => Some((Other::Or, rest))
        (@lexer.TokenType::Keyword, "optional") => Some((Other::Optional, rest))
        (@lexer.TokenType::Keyword, "record") => Some((Other::Record, rest))
        (@lexer.TokenType::Keyword, "sequence") => Some((Other::Sequence, rest))
        (@lexer.TokenType::Keyword, "short") => Some((Other::Short, rest))
        (@lexer.TokenType::Keyword, "symbol") => Some((Other::Symbol, rest))
        (@lexer.TokenType::Keyword, "true") => Some((Other::True, rest))
        (@lexer.TokenType::Keyword, "unsigned") => Some((Other::Unsigned, rest))
        (@lexer.TokenType::Keyword, "undefined") =>
          Some((Other::Undefined, rest))
        _ => {
          guard ArgumentNameKeyword::parse(input)
            is Some((argument_name_keyword, rest)) else {
            guard BufferRelatedType::parse(input)
              is Some((buffer_related_type, rest)) else {
              None
            }
            Some((Other::BufferRelatedType(buffer_related_type), rest))
          }
          Some((Other::ArgumentNameKeyword(argument_name_keyword), rest))
        }
      }
    _ => None
  }
}

///|
pub struct IdentifierList {
  identifier : StringView
  identifiers : Identifiers
}

///|
pub fn IdentifierList::iter(self : Self) -> Iter[StringView] {
  Iter::singleton(self.identifier).concat(self.identifiers.iter())
}

///|
pub fn IdentifierList::parse(input : Tokens) -> (IdentifierList, Tokens)? {
  if input is [(@lexer.TokenType::Identifier, identifier), .. after_identifier] &&
    Identifiers::parse(after_identifier) is (identifiers, rest) {
    return Some((IdentifierList::{ identifier, identifiers }, rest))
  }

  None
}

///|
pub enum Identifiers {
  Some(StringView, Identifiers)
  None
}

///|
pub fn Identifiers::iter(self : Self) -> Iter[StringView] {
  let mut target = self

  Iter::new(() => {
    match target {
      Some(current_identifier, rest) => {
        target = rest

        Some(current_identifier)
      }
      None => None
    }
  })
}

///|
pub fn Identifiers::parse(input : Tokens) -> (Identifiers, Tokens) {
  if input
    is [
      (@lexer.TokenType::Punctuation, ","),
      (@lexer.TokenType::Identifier, identifier),
      .. after_identifier,
    ] &&
    Identifiers::parse(after_identifier) is (identifiers, rest) {
    return (Identifiers::Some(identifier, identifiers), rest)
  }

  (Identifiers::None, input)
}

///|
pub struct IntegerList {
  integer : StringView
  integers : Integers
}

///|
pub fn IntegerList::iter(self : Self) -> Iter[StringView] {
  Iter::singleton(self.integer).concat(self.integers.iter())
}

///|
pub fn IntegerList::parse(input : Tokens) -> (IntegerList, Tokens)? {
  if input is [(@lexer.TokenType::Integer, integer), .. after_integer] &&
    Integers::parse(after_integer) is (integers, rest) {
    return Some((IntegerList::{ integer, integers }, rest))
  }

  None
}

///|
pub enum Integers {
  Some(StringView, Integers)
  None
}

///|
pub fn Integers::iter(self : Self) -> Iter[StringView] {
  let mut target = self

  Iter::new(() => {
    match target {
      Some(current_integer, rest) => {
        target = rest

        Some(current_integer)
      }
      None => None
    }
  })
}

///|
pub fn Integers::parse(input : Tokens) -> (Integers, Tokens) {
  if input
    is [
      (@lexer.TokenType::Punctuation, ","),
      (@lexer.TokenType::Integer, integer),
      .. after_integer,
    ] &&
    Integers::parse(after_integer) is (integers, rest) {
    return (Integers::Some(integer, integers), rest)
  }

  (Integers::None, input)
}

///|
pub struct ExtendedAttributeNoArgs {
  identifier : StringView
}

///|
pub fn ExtendedAttributeNoArgs::parse(
  input : Tokens,
) -> (ExtendedAttributeNoArgs, Tokens)? {
  if input is [(@lexer.TokenType::Identifier, identifier), .. rest] {
    return Some((ExtendedAttributeNoArgs::{ identifier, }, rest))
  }

  None
}

///|
pub struct ExtendedAttributeArgList {
  identifier : StringView
  argument_list : ArgumentList
}

///|
pub fn ExtendedAttributeArgList::parse(
  input : Tokens,
) -> (ExtendedAttributeArgList, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "("),
      .. after_open_paren,
    ] &&
    ArgumentList::parse(after_open_paren)
    is (argument_list, [(@lexer.TokenType::Punctuation, ")"), .. rest]) {
    return Some((ExtendedAttributeArgList::{ identifier, argument_list }, rest))
  }

  None
}

///|
pub struct ExtendedAttributeIdent {
  identifier : StringView
  value : StringView
}

///|
pub fn ExtendedAttributeIdent::parse(
  input : Tokens,
) -> (ExtendedAttributeIdent, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "="),
      (@lexer.TokenType::Identifier, value),
      .. rest,
    ] {
    return Some((ExtendedAttributeIdent::{ identifier, value }, rest))
  }

  None
}

///|
pub struct ExtendedAttributeString {
  identifier : StringView
  value : StringView
}

///|
pub fn ExtendedAttributeString::parse(
  input : Tokens,
) -> (ExtendedAttributeString, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "="),
      (@lexer.TokenType::String, value),
      .. rest,
    ] {
    return Some((ExtendedAttributeString::{ identifier, value }, rest))
  }

  None
}

///|
pub struct ExtendedAttributeInteger {
  identifier : StringView
  value : StringView
}

///|
pub fn ExtendedAttributeInteger::parse(
  input : Tokens,
) -> (ExtendedAttributeInteger, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "="),
      (@lexer.TokenType::Integer, value),
      .. rest,
    ] {
    return Some((ExtendedAttributeInteger::{ identifier, value }, rest))
  }

  None
}

///|
pub struct ExtendedAttributeDecimal {
  identifier : StringView
  value : StringView
}

///|
pub fn ExtendedAttributeDecimal::parse(
  input : Tokens,
) -> (ExtendedAttributeDecimal, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "="),
      (@lexer.TokenType::Decimal, value),
      .. rest,
    ] {
    return Some((ExtendedAttributeDecimal::{ identifier, value }, rest))
  }

  None
}

///|
pub struct ExtendedAttributeWildcard {
  identifier : StringView
}

///|
pub fn ExtendedAttributeWildcard::parse(
  input : Tokens,
) -> (ExtendedAttributeWildcard, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "="),
      (@lexer.TokenType::Punctuation, "*"),
      .. rest,
    ] {
    return Some((ExtendedAttributeWildcard::{ identifier, }, rest))
  }

  None
}

///|
pub struct ExtendedAttributeIdentList {
  identifier : StringView
  identifier_list : IdentifierList
}

///|
pub fn ExtendedAttributeIdentList::parse(
  input : Tokens,
) -> (ExtendedAttributeIdentList, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "="),
      (@lexer.TokenType::Punctuation, "("),
      .. after_open_paren,
    ] &&
    IdentifierList::parse(after_open_paren)
    is Some((identifier_list, [(@lexer.TokenType::Punctuation, ")"), .. rest])) {
    return Some(
      (ExtendedAttributeIdentList::{ identifier, identifier_list }, rest),
    )
  }

  None
}

///|
pub struct ExtendedAttributeIntegerList {
  identifier : StringView
  integer_list : IntegerList
}

///|
pub fn ExtendedAttributeIntegerList::parse(
  input : Tokens,
) -> (ExtendedAttributeIntegerList, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "="),
      (@lexer.TokenType::Punctuation, "("),
      .. after_open_paren,
    ] &&
    IntegerList::parse(after_open_paren)
    is Some((integer_list, [(@lexer.TokenType::Punctuation, ")"), .. rest])) {
    return Some(
      (ExtendedAttributeIntegerList::{ identifier, integer_list }, rest),
    )
  }

  None
}

///|
pub struct ExtendedAttributeNamedArgList {
  identifier : StringView
  value : StringView
  argument_list : ArgumentList
}

///|
pub fn ExtendedAttributeNamedArgList::parse(
  input : Tokens,
) -> (ExtendedAttributeNamedArgList, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "="),
      (@lexer.TokenType::Identifier, value),
      (@lexer.TokenType::Punctuation, "("),
      .. after_open_paren,
    ] &&
    ArgumentList::parse(after_open_paren)
    is (argument_list, [(@lexer.TokenType::Punctuation, ")"), .. rest]) {
    return Some(
      (
        ExtendedAttributeNamedArgList::{ identifier, value, argument_list },
        rest,
      ),
    )
  }

  None
}
