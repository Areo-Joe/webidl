///|
pub type Tokens = ArrayView[(@lexer.TokenType, StringView)]

///|
pub enum ExtendedAttributeList {
  Some(ExtendedAttribute, ExtendedAttributes)
  None
} derive(Debug)

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
} derive(Debug)

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
pub enum ExtendedAttribute {
  Parentheses(ExtendedAttributeInner, ExtendedAttributeRest)
  Brackets(ExtendedAttributeInner, ExtendedAttributeRest)
  Braces(ExtendedAttributeInner, ExtendedAttributeRest)
  Other(Other, ExtendedAttributeRest)
} derive(Debug)

///|
pub fn ExtendedAttribute::parse(input : Tokens) -> (ExtendedAttribute, Tokens)? {
  fn parse_other(input : Tokens) -> (ExtendedAttribute, Tokens)? {
    guard Other::parse(input) is Some((other, after_other)) else { None }

    let (extended_attribute_rest, rest) = ExtendedAttributeRest::parse(
      after_other,
    )

    Some((ExtendedAttribute::Other(other, extended_attribute_rest), rest))
  }

  match input {
    [first, .. rest] =>
      match first {
        (@lexer.TokenType::Punctuation, "(") => {
          let (extended_attribute_inner, after_inner) = ExtendedAttributeInner::parse(
            rest,
          )

          guard after_inner
            is [(@lexer.TokenType::Punctuation, ")"), .. after_parentheses] else {
            None
          }

          let (extended_attribute_rest, after_outer) = ExtendedAttributeRest::parse(
            after_parentheses,
          )

          Some(
            (
              ExtendedAttribute::Parentheses(
                extended_attribute_inner, extended_attribute_rest,
              ),
              after_outer,
            ),
          )
        }
        (@lexer.TokenType::Punctuation, "{") => {
          let (extended_attribute_inner, after_inner) = ExtendedAttributeInner::parse(
            rest,
          )

          guard after_inner
            is [(@lexer.TokenType::Punctuation, "}"), .. after_braces] else {
            None
          }

          let (extended_attribute_rest, after_outer) = ExtendedAttributeRest::parse(
            after_braces,
          )

          Some(
            (
              ExtendedAttribute::Braces(
                extended_attribute_inner, extended_attribute_rest,
              ),
              after_outer,
            ),
          )
        }
        (@lexer.TokenType::Punctuation, "[") => {
          let (extended_attribute_inner, after_inner) = ExtendedAttributeInner::parse(
            rest,
          )

          guard after_inner
            is [(@lexer.TokenType::Punctuation, "]"), .. after_brackets] else {
            None
          }

          let (extended_attribute_rest, after_outer) = ExtendedAttributeRest::parse(
            after_brackets,
          )

          Some(
            (
              ExtendedAttribute::Brackets(
                extended_attribute_inner, extended_attribute_rest,
              ),
              after_outer,
            ),
          )
        }
        _ => parse_other(input)
      }
    _ => parse_other(input)
  }
}

///|
pub enum ExtendedAttributeRest {
  ExtendedAttribute(ExtendedAttribute)
  None
} derive(Debug)

///|
pub fn ExtendedAttributeRest::parse(
  input : Tokens,
) -> (ExtendedAttributeRest, Tokens) {
  match ExtendedAttribute::parse(input) {
    Some((extended_attribute, rest)) =>
      (ExtendedAttributeRest::ExtendedAttribute(extended_attribute), rest)
    None => (ExtendedAttributeRest::None, input)
  }
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
pub struct Constructor {
  argument_list : ArgumentList
}

///|
pub fn Constructor::parse(input : Tokens) -> (Constructor, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "constructor"),
      (@lexer.TokenType::Punctuation, "("),
      .. after_constructor_start,
    ] &&
    ArgumentList::parse(after_constructor_start)
    is (
      argument_list,
      [
        (@lexer.TokenType::Punctuation, ")"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some((Constructor::{ argument_list, }, rest))
  }

  return None
}

///|
pub struct Const {
  const_type : ConstType
  identifier : StringView
  const_value : ConstValue
}

///|
pub fn Const::parse(input : Tokens) -> (Const, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "const"), .. after_const] &&
    ConstType::parse(after_const)
    is Some(
      (
        const_type,
        [
          (@lexer.TokenType::Identifier, identifier),
          (@lexer.TokenType::Punctuation, "="),
          .. after_equal,
        ],
      )
    ) &&
    ConstValue::parse(after_equal)
    is Some((const_value, [(@lexer.TokenType::Punctuation, ";"), .. rest])) {
    return Some((Const::{ const_type, identifier, const_value }, rest))
  }

  return None
}

///|
pub enum OptionalReadOnly {
  ReadOnly
  None
} derive(Debug)

///|
pub fn OptionalReadOnly::parse(input : Tokens) -> (OptionalReadOnly, Tokens) {
  if input is [(@lexer.TokenType::Keyword, "readonly"), .. rest] {
    return (OptionalReadOnly::ReadOnly, rest)
  }
  return (OptionalReadOnly::None, input)
}

///|
pub enum StaticMemberRest {
  Attribute(OptionalReadOnly, AttributeRest)
  RegularOperation(RegularOperation)
}

///|
pub fn StaticMemberRest::parse(input : Tokens) -> (StaticMemberRest, Tokens)? {
  if OptionalReadOnly::parse(input)
    is (optional_read_only, after_optional_read_only) &&
    AttributeRest::parse(after_optional_read_only)
    is Some((attribute_rest, rest)) {
    return Some(
      (StaticMemberRest::Attribute(optional_read_only, attribute_rest), rest),
    )
  }

  if RegularOperation::parse(input) is Some((regular_operation, rest)) {
    return Some((StaticMemberRest::RegularOperation(regular_operation), rest))
  }

  None
}

///|
pub struct StaticMember {
  static_member_rest : StaticMemberRest
}

///|
pub fn StaticMember::parse(input : Tokens) -> (StaticMember, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "static"), .. after_static] &&
    StaticMemberRest::parse(after_static) is Some((static_member_rest, rest)) {
    return Some((StaticMember::{ static_member_rest, }, rest))
  }

  None
}

///|
pub enum OptionalType {
  Some(TypeWithExtendedAttributes)
  None
}

///|
pub fn OptionalType::parse(input : Tokens) -> (OptionalType, Tokens) {
  if input is [(@lexer.TokenType::Punctuation, ","), .. after_comma] &&
    TypeWithExtendedAttributes::parse(after_comma)
    is Some((type_with_extended_attributes, rest)) {
    return (OptionalType::Some(type_with_extended_attributes), rest)
  }
  return (OptionalType::None, input)
}

///|
pub struct Iterable {
  type_with_extended_attributes : TypeWithExtendedAttributes
  optional_type : OptionalType
}

///|
pub fn Iterable::parse(input : Tokens) -> (Iterable, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "iterable"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_iterable_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_iterable_start)
    is Some(
      (type_with_extended_attributes, after_type_with_extended_attributes)
    ) &&
    OptionalType::parse(after_type_with_extended_attributes)
    is (
      optional_type,
      [
        (@lexer.TokenType::Punctuation, ">"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some(
      (Iterable::{ type_with_extended_attributes, optional_type }, rest),
    )
  }

  None
}

///|
pub enum OptionalArgumentList {
  Some(ArgumentList)
  None
}

///|
pub fn OptionalArgumentList::parse(
  input : Tokens,
) -> (OptionalArgumentList, Tokens) {
  if input is [(@lexer.TokenType::Punctuation, "("), .. after_open_paren] &&
    ArgumentList::parse(after_open_paren)
    is (argument_list, [(@lexer.TokenType::Punctuation, ")"), .. rest]) {
    return (OptionalArgumentList::Some(argument_list), rest)
  }

  return (OptionalArgumentList::None, input)
}

///|
pub struct AsyncIterable {
  type_with_extended_attributes : TypeWithExtendedAttributes
  optional_type : OptionalType
  optional_argument_list : OptionalArgumentList
}

///|
pub fn AsyncIterable::parse(input : Tokens) -> (AsyncIterable, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "async_iterable"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_async_iterable_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_async_iterable_start)
    is Some(
      (type_with_extended_attributes, after_type_with_extended_attributes)
    ) &&
    OptionalType::parse(after_type_with_extended_attributes)
    is (
      optional_type,
      [(@lexer.TokenType::Punctuation, ">"), .. after_async_iterable_end],
    ) &&
    OptionalArgumentList::parse(after_async_iterable_end)
    is (optional_argument_list, [(@lexer.TokenType::Punctuation, ";"), .. rest]) {
    return Some(
      (
        AsyncIterable::{
          type_with_extended_attributes,
          optional_type,
          optional_argument_list,
        },
        rest,
      ),
    )
  }

  None
}

///|
pub struct MaplikeRest {
  key_type : TypeWithExtendedAttributes
  value_type : TypeWithExtendedAttributes
}

///|
pub fn MaplikeRest::parse(input : Tokens) -> (MaplikeRest, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "maplike"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_maplike_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_maplike_start)
    is Some((key_type, [(@lexer.TokenType::Punctuation, ","), .. after_comma])) &&
    TypeWithExtendedAttributes::parse(after_comma)
    is Some(
      (
        value_type,
        [
          (@lexer.TokenType::Punctuation, ">"),
          (@lexer.TokenType::Punctuation, ";"),
          .. rest,
        ],
      )
    ) {
    return Some((MaplikeRest::{ key_type, value_type }, rest))
  }

  None
}

///|
pub struct SetlikeRest {
  type_with_extended_attributes : TypeWithExtendedAttributes
}

///|
pub fn SetlikeRest::parse(input : Tokens) -> (SetlikeRest, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "setlike"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_setlike_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_setlike_start)
    is Some(
      (
        type_with_extended_attributes,
        [
          (@lexer.TokenType::Punctuation, ">"),
          (@lexer.TokenType::Punctuation, ";"),
          .. rest,
        ],
      )
    ) {
    return Some((SetlikeRest::{ type_with_extended_attributes, }, rest))
  }

  None
}

///|
pub enum ReadOnlyMemberRest {
  Attribute(AttributeRest)
  Maplike(MaplikeRest)
  Setlike(SetlikeRest)
}

///|
pub fn ReadOnlyMemberRest::parse(
  input : Tokens,
) -> (ReadOnlyMemberRest, Tokens)? {
  if AttributeRest::parse(input) is Some((attribute_rest, rest)) {
    return Some((ReadOnlyMemberRest::Attribute(attribute_rest), rest))
  }

  if MaplikeRest::parse(input) is Some((maplike_rest, rest)) {
    return Some((ReadOnlyMemberRest::Maplike(maplike_rest), rest))
  }

  if SetlikeRest::parse(input) is Some((setlike_rest, rest)) {
    return Some((ReadOnlyMemberRest::Setlike(setlike_rest), rest))
  }

  None
}

///|
pub struct ReadOnlyMember {
  read_only_member_rest : ReadOnlyMemberRest
}

///|
pub fn ReadOnlyMember::parse(input : Tokens) -> (ReadOnlyMember, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "readonly"), .. after_readonly] &&
    ReadOnlyMemberRest::parse(after_readonly)
    is Some((read_only_member_rest, rest)) {
    return Some((ReadOnlyMember::{ read_only_member_rest, }, rest))
  }

  None
}

///|
pub struct ReadWriteMaplike {
  maplike_rest : MaplikeRest
}

///|
pub fn ReadWriteMaplike::parse(input : Tokens) -> (ReadWriteMaplike, Tokens)? {
  if MaplikeRest::parse(input) is Some((maplike_rest, rest)) {
    return Some((ReadWriteMaplike::{ maplike_rest, }, rest))
  }

  None
}

///|
pub struct ReadWriteSetlike {
  setlike_rest : SetlikeRest
}

///|
pub fn ReadWriteSetlike::parse(input : Tokens) -> (ReadWriteSetlike, Tokens)? {
  if SetlikeRest::parse(input) is Some((setlike_rest, rest)) {
    return Some((ReadWriteSetlike::{ setlike_rest, }, rest))
  }

  None
}

///|
pub enum PartialInterfaceMember {
  Const(Const)
  Operation(Operation)
  Stringifier(Stringifier)
  StaticMember(StaticMember)
  Iterable(Iterable)
  AsyncIterable(AsyncIterable)
  ReadOnlyMember(ReadOnlyMember)
  ReadWriteAttribute(ReadWriteAttribute)
  ReadWriteMaplike(ReadWriteMaplike)
  ReadWriteSetlike(ReadWriteSetlike)
  InheritAttribute(InheritAttribute)
}

///|
pub fn PartialInterfaceMember::parse(
  input : Tokens,
) -> (PartialInterfaceMember, Tokens)? {
  if Const::parse(input) is Some((const_, rest)) {
    return Some((PartialInterfaceMember::Const(const_), rest))
  }

  if Operation::parse(input) is Some((operation, rest)) {
    return Some((PartialInterfaceMember::Operation(operation), rest))
  }

  if Stringifier::parse(input) is Some((stringifier, rest)) {
    return Some((PartialInterfaceMember::Stringifier(stringifier), rest))
  }

  if StaticMember::parse(input) is Some((static_member, rest)) {
    return Some((PartialInterfaceMember::StaticMember(static_member), rest))
  }

  if Iterable::parse(input) is Some((iterable, rest)) {
    return Some((PartialInterfaceMember::Iterable(iterable), rest))
  }

  if AsyncIterable::parse(input) is Some((async_iterable, rest)) {
    return Some((PartialInterfaceMember::AsyncIterable(async_iterable), rest))
  }

  if ReadOnlyMember::parse(input) is Some((read_only_member, rest)) {
    return Some(
      (PartialInterfaceMember::ReadOnlyMember(read_only_member), rest),
    )
  }

  if ReadWriteAttribute::parse(input) is Some((read_write_attribute, rest)) {
    return Some(
      (PartialInterfaceMember::ReadWriteAttribute(read_write_attribute), rest),
    )
  }

  if ReadWriteMaplike::parse(input) is Some((read_write_maplike, rest)) {
    return Some(
      (PartialInterfaceMember::ReadWriteMaplike(read_write_maplike), rest),
    )
  }

  if ReadWriteSetlike::parse(input) is Some((read_write_setlike, rest)) {
    return Some(
      (PartialInterfaceMember::ReadWriteSetlike(read_write_setlike), rest),
    )
  }

  if InheritAttribute::parse(input) is Some((inherit_attribute, rest)) {
    return Some(
      (PartialInterfaceMember::InheritAttribute(inherit_attribute), rest),
    )
  }

  None
}

///|
pub enum PartialInterfaceMembers {
  Some(ExtendedAttributeList, PartialInterfaceMember, PartialInterfaceMembers)
  None
}

///|
pub fn PartialInterfaceMembers::parse(
  input : Tokens,
) -> (PartialInterfaceMembers, Tokens) {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    PartialInterfaceMember::parse(after_extended_attribute_list)
    is Some((partial_interface_member, after_partial_interface_member)) &&
    PartialInterfaceMembers::parse(after_partial_interface_member)
    is (partial_interface_members, rest) {
    return (
      PartialInterfaceMembers::Some(
        extended_attribute_list, partial_interface_member, partial_interface_members,
      ),
      rest,
    )
  }

  (PartialInterfaceMembers::None, input)
}

///|
pub struct PartialInterfaceRest {
  identifier : StringView
  partial_interface_members : PartialInterfaceMembers
}

///|
pub fn PartialInterfaceRest::parse(
  input : Tokens,
) -> (PartialInterfaceRest, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "{"),
      .. after_partial_interface_start,
    ] &&
    PartialInterfaceMembers::parse(after_partial_interface_start)
    is (
      partial_interface_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some(
      (PartialInterfaceRest::{ identifier, partial_interface_members }, rest),
    )
  }

  None
}

///|
pub enum MixinMember {
  Const(Const)
  RegularOperation(RegularOperation)
  Stringifier(Stringifier)
  Attribute(OptionalReadOnly, AttributeRest)
}

///|
pub fn MixinMember::parse(input : Tokens) -> (MixinMember, Tokens)? {
  if Const::parse(input) is Some((const_, rest)) {
    return Some((MixinMember::Const(const_), rest))
  }

  if RegularOperation::parse(input) is Some((regular_operation, rest)) {
    return Some((MixinMember::RegularOperation(regular_operation), rest))
  }

  if Stringifier::parse(input) is Some((stringifier, rest)) {
    return Some((MixinMember::Stringifier(stringifier), rest))
  }

  if OptionalReadOnly::parse(input)
    is (optional_read_only, after_optional_read_only) &&
    AttributeRest::parse(after_optional_read_only)
    is Some((attribute_rest, rest)) {
    return Some(
      (MixinMember::Attribute(optional_read_only, attribute_rest), rest),
    )
  }

  None
}

///|
pub enum MixinMembers {
  Some(ExtendedAttributeList, MixinMember, MixinMembers)
  None
}

///|
pub fn MixinMembers::parse(input : Tokens) -> (MixinMembers, Tokens) {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    MixinMember::parse(after_extended_attribute_list)
    is Some((mixin_member, after_mixin_member)) &&
    MixinMembers::parse(after_mixin_member) is (mixin_members, rest) {
    return (
      MixinMembers::Some(extended_attribute_list, mixin_member, mixin_members),
      rest,
    )
  }

  (MixinMembers::None, input)
}

///|
pub struct MixinRest {
  identifier : StringView
  mixin_members : MixinMembers
}

///|
pub fn MixinRest::parse(input : Tokens) -> (MixinRest, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "mixin"),
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "{"),
      .. after_mixin_start,
    ] &&
    MixinMembers::parse(after_mixin_start)
    is (
      mixin_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some((MixinRest::{ identifier, mixin_members }, rest))
  }

  None
}

///|
pub enum PartialInterfaceOrPartialMixin {
  PartialInterfaceRest(PartialInterfaceRest)
  MixinRest(MixinRest)
}

///|
pub fn PartialInterfaceOrPartialMixin::parse(
  input : Tokens,
) -> (PartialInterfaceOrPartialMixin, Tokens)? {
  if PartialInterfaceRest::parse(input) is Some((partial_interface_rest, rest)) {
    return Some(
      (
        PartialInterfaceOrPartialMixin::PartialInterfaceRest(
          partial_interface_rest,
        ),
        rest,
      ),
    )
  }

  if MixinRest::parse(input) is Some((mixin_rest, rest)) {
    return Some((PartialInterfaceOrPartialMixin::MixinRest(mixin_rest), rest))
  }

  None
}

///|
pub enum Inheritance {
  Some(StringView)
  None
}

///|
pub fn Inheritance::parse(input : Tokens) -> (Inheritance, Tokens) {
  if input
    is [
      (@lexer.TokenType::Punctuation, ":"),
      (@lexer.TokenType::Identifier, identifier),
      .. rest,
    ] {
    return (Inheritance::Some(identifier), rest)
  }

  (Inheritance::None, input)
}

///|
pub enum DictionaryMemberRest {
  Required(TypeWithExtendedAttributes, StringView)
  Optional(Type, StringView, Default)
}

///|
pub fn DictionaryMemberRest::parse(
  input : Tokens,
) -> (DictionaryMemberRest, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "required"), .. after_required] &&
    TypeWithExtendedAttributes::parse(after_required)
    is Some(
      (
        type_with_extended_attributes,
        [
          (@lexer.TokenType::Identifier, identifier),
          (@lexer.TokenType::Punctuation, ";"),
          .. rest,
        ],
      )
    ) {
    return Some(
      (
        DictionaryMemberRest::Required(
          type_with_extended_attributes, identifier,
        ),
        rest,
      ),
    )
  }

  if Type::parse(input)
    is Some(
      (type_, [(@lexer.TokenType::Identifier, identifier), .. after_identifier])
    ) &&
    Default::parse(after_identifier)
    is (default, [(@lexer.TokenType::Punctuation, ";"), .. rest]) {
    return Some(
      (DictionaryMemberRest::Optional(type_, identifier, default), rest),
    )
  }

  None
}

///|
pub struct DictionaryMember {
  extended_attribute_list : ExtendedAttributeList
  dictionary_member_rest : DictionaryMemberRest
}

///|
pub fn DictionaryMember::parse(input : Tokens) -> (DictionaryMember, Tokens)? {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    DictionaryMemberRest::parse(after_extended_attribute_list)
    is Some((dictionary_member_rest, rest)) {
    return Some(
      (
        DictionaryMember::{ extended_attribute_list, dictionary_member_rest },
        rest,
      ),
    )
  }

  None
}

///|
pub enum DictionaryMembers {
  Some(DictionaryMember, DictionaryMembers)
  None
}

///|
pub fn DictionaryMembers::parse(input : Tokens) -> (DictionaryMembers, Tokens) {
  if DictionaryMember::parse(input)
    is Some((dictionary_member, after_dictionary_member)) &&
    DictionaryMembers::parse(after_dictionary_member)
    is (dictionary_members, rest) {
    return (
      DictionaryMembers::Some(dictionary_member, dictionary_members),
      rest,
    )
  }

  (DictionaryMembers::None, input)
}

///|
pub struct Dictionary {
  identifier : StringView
  inheritance : Inheritance
  dictionary_members : DictionaryMembers
}

///|
pub fn Dictionary::parse(input : Tokens) -> (Dictionary, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "dictionary"),
      (@lexer.TokenType::Identifier, identifier),
      .. after_identifier,
    ] &&
    Inheritance::parse(after_identifier)
    is (
      inheritance,
      [(@lexer.TokenType::Punctuation, "{"), .. after_dictionary_start],
    ) &&
    DictionaryMembers::parse(after_dictionary_start)
    is (
      dictionary_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some(
      (Dictionary::{ identifier, inheritance, dictionary_members }, rest),
    )
  }

  None
}

///|
pub struct PartialDictionary {
  identifier : StringView
  dictionary_members : DictionaryMembers
}

///|
pub fn PartialDictionary::parse(input : Tokens) -> (PartialDictionary, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "dictionary"),
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "{"),
      .. after_dictionary_start,
    ] &&
    DictionaryMembers::parse(after_dictionary_start)
    is (
      dictionary_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some((PartialDictionary::{ identifier, dictionary_members }, rest))
  }

  None
}

///|
pub enum NamespaceMember {
  RegularOperation(RegularOperation)
  ReadOnlyAttribute(AttributeRest)
  Const(Const)
}

///|
pub fn NamespaceMember::parse(input : Tokens) -> (NamespaceMember, Tokens)? {
  if RegularOperation::parse(input) is Some((regular_operation, rest)) {
    return Some((NamespaceMember::RegularOperation(regular_operation), rest))
  }

  if input is [(@lexer.TokenType::Keyword, "readonly"), .. after_readonly] &&
    AttributeRest::parse(after_readonly) is Some((attribute_rest, rest)) {
    return Some((NamespaceMember::ReadOnlyAttribute(attribute_rest), rest))
  }

  if Const::parse(input) is Some((const_, rest)) {
    return Some((NamespaceMember::Const(const_), rest))
  }

  None
}

///|
pub enum NamespaceMembers {
  Some(ExtendedAttributeList, NamespaceMember, NamespaceMembers)
  None
}

///|
pub fn NamespaceMembers::parse(input : Tokens) -> (NamespaceMembers, Tokens) {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    NamespaceMember::parse(after_extended_attribute_list)
    is Some((namespace_member, after_namespace_member)) &&
    NamespaceMembers::parse(after_namespace_member) is (namespace_members, rest) {
    return (
      NamespaceMembers::Some(
        extended_attribute_list, namespace_member, namespace_members,
      ),
      rest,
    )
  }

  (NamespaceMembers::None, input)
}

///|
pub struct Namespace {
  identifier : StringView
  namespace_members : NamespaceMembers
}

///|
pub fn Namespace::parse(input : Tokens) -> (Namespace, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "namespace"),
      (@lexer.TokenType::Identifier, identifier),
      (@lexer.TokenType::Punctuation, "{"),
      .. after_namespace_start,
    ] &&
    NamespaceMembers::parse(after_namespace_start)
    is (
      namespace_members,
      [
        (@lexer.TokenType::Punctuation, "}"),
        (@lexer.TokenType::Punctuation, ";"),
        .. rest,
      ],
    ) {
    return Some((Namespace::{ identifier, namespace_members }, rest))
  }

  None
}
