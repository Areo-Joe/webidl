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
