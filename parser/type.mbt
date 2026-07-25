///|
pub enum Type {
  SingleType(SingleType)
  UnionType(UnionType, Null)
}

///|
pub fn Type::parse(input : Tokens) -> (Type, Tokens)? {
  if SingleType::parse(input) is Some((single_type, rest)) {
    return Some((Type::SingleType(single_type), rest))
  }

  if UnionType::parse(input) is Some((union_type, after_union_type)) &&
    Null::parse(after_union_type) is (null, rest) {
    return Some((Type::UnionType(union_type, null), rest))
  }

  None
}

///|
pub struct TypeWithExtendedAttributes {
  extended_attribute_list : ExtendedAttributeList
  type_ : Type
}

///|
pub fn TypeWithExtendedAttributes::parse(
  input : Tokens,
) -> (TypeWithExtendedAttributes, Tokens)? {
  let (extended_attribute_list, after_extended_attribute_list) = ExtendedAttributeList::parse(
    input,
  )

  guard Type::parse(after_extended_attribute_list) is Some((type_, rest)) else {
    return None
  }

  Some((TypeWithExtendedAttributes::{ extended_attribute_list, type_ }, rest))
}

///|
pub struct RecordType {
  string_type : StringType
  type_with_extended_attributes : TypeWithExtendedAttributes
}

///|
pub fn RecordType::parse(input : Tokens) -> (RecordType, Tokens)? {
  guard input
    is [
      (@lexer.TokenType::Keyword, "record"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_record_start,
    ] else {
    None
  }

  guard StringType::parse(after_record_start)
    is Some((string_type, after_string_type)) else {
    return None
  }

  guard after_string_type
    is [(@lexer.TokenType::Punctuation, ","), .. after_comma] else {
    return None
  }

  guard TypeWithExtendedAttributes::parse(after_comma)
    is Some(
      (type_with_extended_attributes, after_type_with_extended_attributes)
    ) else {
    return None
  }

  guard after_type_with_extended_attributes
    is [(@lexer.TokenType::Punctuation, ">"), .. after_record_end] else {
    return None
  }

  return Some(
    (
      RecordType::{ string_type, type_with_extended_attributes },
      after_record_end,
    ),
  )
}

///|
pub enum DistinguishableType {
  PrimitiveType(PrimitiveType, Null)
  StringType(StringType, Null)
  Identifier(StringView, Null)
  Sequence(TypeWithExtendedAttributes, Null)
  AsyncSequence(TypeWithExtendedAttributes, Null)
  Object(Null)
  Symbol(Null)
  BufferRelatedType(BufferRelatedType, Null)
  FrozenArray(TypeWithExtendedAttributes, Null)
  ObservableArray(TypeWithExtendedAttributes, Null)
  RecordType(RecordType, Null)
  Undefined(Null)
}

///|
pub fn DistinguishableType::parse(
  input : Tokens,
) -> (DistinguishableType, Tokens)? {
  if PrimitiveType::parse(input) is Some((primitive_type, after_primitive_type)) {
    let (null, rest) = Null::parse(after_primitive_type)

    return Some(
      (DistinguishableType::PrimitiveType(primitive_type, null), rest),
    )
  }

  if StringType::parse(input) is Some((string_type, after_string_type)) {
    let (null, rest) = Null::parse(after_string_type)

    return Some((DistinguishableType::StringType(string_type, null), rest))
  }

  if input is [(@lexer.TokenType::Identifier, identifier), .. after_identifier] {
    let (null, rest) = Null::parse(after_identifier)
    return Some((DistinguishableType::Identifier(identifier, null), rest))
  }

  if input
    is [
      (@lexer.TokenType::Keyword, "sequence"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_sequence_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_sequence_start)
    is Some(
      (type_with_extended_attributes, after_type_with_extended_attributes)
    ) &&
    after_type_with_extended_attributes
    is [(@lexer.TokenType::Punctuation, ">"), .. after_sequence_end] &&
    Null::parse(after_sequence_end) is (null, rest) {
    return Some(
      (DistinguishableType::Sequence(type_with_extended_attributes, null), rest),
    )
  }

  if input
    is [
      (@lexer.TokenType::Keyword, "async_sequence"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_async_sequence_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_async_sequence_start)
    is Some(
      (type_with_extended_attributes, after_type_with_extended_attributes)
    ) &&
    after_type_with_extended_attributes
    is [(@lexer.TokenType::Punctuation, ">"), .. after_async_sequence_end] &&
    Null::parse(after_async_sequence_end) is (null, rest) {
    return Some(
      (
        DistinguishableType::AsyncSequence(type_with_extended_attributes, null),
        rest,
      ),
    )
  }

  if input is [(@lexer.TokenType::Keyword, "object"), .. after_object] &&
    Null::parse(after_object) is (null, rest) {
    return Some((DistinguishableType::Object(null), rest))
  }

  if input is [(@lexer.TokenType::Keyword, "symbol"), .. after_symbol] &&
    Null::parse(after_symbol) is (null, rest) {
    return Some((DistinguishableType::Symbol(null), rest))
  }

  if BufferRelatedType::parse(input)
    is Some((buffer_related_type, after_buffer_related_type)) &&
    Null::parse(after_buffer_related_type) is (null, rest) {
    return Some(
      (DistinguishableType::BufferRelatedType(buffer_related_type, null), rest),
    )
  }

  if input
    is [
      (@lexer.TokenType::Keyword, "FrozenArray"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_frozen_array_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_frozen_array_start)
    is Some(
      (type_with_extended_attributes, after_type_with_extended_attributes)
    ) &&
    after_type_with_extended_attributes
    is [(@lexer.TokenType::Punctuation, ">"), .. after_frozen_array_end] &&
    Null::parse(after_frozen_array_end) is (null, rest) {
    return Some(
      (
        DistinguishableType::FrozenArray(type_with_extended_attributes, null),
        rest,
      ),
    )
  }

  if input
    is [
      (@lexer.TokenType::Keyword, "ObservableArray"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_observable_array_start,
    ] &&
    TypeWithExtendedAttributes::parse(after_observable_array_start)
    is Some(
      (type_with_extended_attributes, after_type_with_extended_attributes)
    ) &&
    after_type_with_extended_attributes
    is [(@lexer.TokenType::Punctuation, ">"), .. after_observable_array_end] &&
    Null::parse(after_observable_array_end) is (null, rest) {
    return Some(
      (
        DistinguishableType::ObservableArray(
          type_with_extended_attributes, null,
        ),
        rest,
      ),
    )
  }

  if RecordType::parse(input) is Some((record_type, after_record_type)) &&
    Null::parse(after_record_type) is (null, rest) {
    return Some((DistinguishableType::RecordType(record_type, null), rest))
  }

  if input is [(@lexer.TokenType::Keyword, "undefined"), .. after_undefined] &&
    Null::parse(after_undefined) is (null, rest) {
    return Some((DistinguishableType::Undefined(null), rest))
  }

  return None
}

///|
pub enum Null {
  Some
  None
} derive(Debug)

///|
pub fn Null::parse(input : Tokens) -> (Null, Tokens) {
  match input {
    [(@lexer.TokenType::Punctuation, "?"), .. rest] => (Null::Some, rest)
    _ => (Null::None, input)
  }
}

///|
pub enum StringType {
  ByteString
  DOMString
  USVString
} derive(Debug)

///|
pub fn StringType::parse(input : Tokens) -> (StringType, Tokens)? {
  match input {
    [(@lexer.TokenType::Keyword, "ByteString"), .. rest] =>
      Some((StringType::ByteString, rest))
    [(@lexer.TokenType::Keyword, "DOMString"), .. rest] =>
      Some((StringType::DOMString, rest))
    [(@lexer.TokenType::Keyword, "USVString"), .. rest] =>
      Some((StringType::USVString, rest))
    _ => None
  }
}

///|
pub enum OptionalLong {
  Long
  None
}

///|
pub fn OptionalLong::parse(input : Tokens) -> (OptionalLong, Tokens) {
  match input {
    [(@lexer.TokenType::Keyword, "long"), .. rest] => (OptionalLong::Long, rest)
    _ => (OptionalLong::None, input)
  }
}

///|
pub enum IntegerType {
  Short
  Long(OptionalLong)
}

///|
pub fn IntegerType::parse(input : Tokens) -> (IntegerType, Tokens)? {
  match input {
    [(@lexer.TokenType::Keyword, "short"), .. rest] =>
      Some((IntegerType::Short, rest))
    [(@lexer.TokenType::Keyword, "long"), .. after_long] => {
      let (optional_long, rest) = OptionalLong::parse(after_long)

      Some((IntegerType::Long(optional_long), rest))
    }
    _ => None
  }
}

///|
pub enum UnsignedIntegerType {
  UnsignedIntegerType(IntegerType)
  IntegerType(IntegerType)
}

///|
pub fn UnsignedIntegerType::parse(
  input : Tokens,
) -> (UnsignedIntegerType, Tokens)? {
  match input {
    [(@lexer.TokenType::Keyword, "unsigned"), .. after_unsigned] => {
      guard IntegerType::parse(after_unsigned) is Some((integer_type, rest)) else {
        None
      }

      Some((UnsignedIntegerType::UnsignedIntegerType(integer_type), rest))
    }
    _ => {
      guard IntegerType::parse(input) is Some((integer_type, rest)) else {
        None
      }

      Some((UnsignedIntegerType::IntegerType(integer_type), rest))
    }
  }
}

///|
pub enum FloatType {
  Float
  Double
}

///|
pub fn FloatType::parse(input : Tokens) -> (FloatType, Tokens)? {
  match input {
    [(@lexer.TokenType::Keyword, "float"), .. rest] =>
      Some((FloatType::Float, rest))
    [(@lexer.TokenType::Keyword, "double"), .. rest] =>
      Some((FloatType::Double, rest))
    _ => None
  }
}

///|
pub enum UnrestrictedFloatType {
  UnrestrictedFloatType(FloatType)
  FloatType(FloatType)
}

///|
pub fn UnrestrictedFloatType::parse(
  input : Tokens,
) -> (UnrestrictedFloatType, Tokens)? {
  match input {
    [(@lexer.TokenType::Keyword, "unrestricted"), .. after_unrestricted] => {
      guard FloatType::parse(after_unrestricted) is Some((float_type, rest)) else {
        None
      }

      Some((UnrestrictedFloatType::UnrestrictedFloatType(float_type), rest))
    }
    _ => {
      guard FloatType::parse(input) is Some((float_type, rest)) else { None }

      Some((UnrestrictedFloatType::FloatType(float_type), rest))
    }
  }
}

///|
pub enum PrimitiveType {
  UnsignedIntegerType(UnsignedIntegerType)
  UnrestrictedFloatType(UnrestrictedFloatType)
  Boolean
  Byte
  Octet
  Bigint
}

///|
pub fn PrimitiveType::parse(input : Tokens) -> (PrimitiveType, Tokens)? {
  if UnsignedIntegerType::parse(input) is Some((unsigned_integer_type, rest)) {
    return Some(
      (PrimitiveType::UnsignedIntegerType(unsigned_integer_type), rest),
    )
  }

  if UnrestrictedFloatType::parse(input)
    is Some((unrestricted_float_type, rest)) {
    return Some(
      (PrimitiveType::UnrestrictedFloatType(unrestricted_float_type), rest),
    )
  }

  match input {
    [(@lexer.TokenType::Keyword, "boolean"), .. rest] =>
      Some((PrimitiveType::Boolean, rest))
    [(@lexer.TokenType::Keyword, "byte"), .. rest] =>
      Some((PrimitiveType::Byte, rest))
    [(@lexer.TokenType::Keyword, "octet"), .. rest] =>
      Some((PrimitiveType::Octet, rest))
    [(@lexer.TokenType::Keyword, "bigint"), .. rest] =>
      Some((PrimitiveType::Bigint, rest))
    _ => None
  }
}

///|
pub enum BufferRelatedType {
  ArrayBuffer
  SharedArrayBuffer
  DataView
  Int8Array
  Int16Array
  Int32Array
  Uint8Array
  Uint16Array
  Uint32Array
  Uint8ClampedArray
  BigInt64Array
  BigUint64Array
  Float16Array
  Float32Array
  Float64Array
} derive(Debug)

///|
pub fn BufferRelatedType::parse(input : Tokens) -> (BufferRelatedType, Tokens)? {
  match input {
    [first, .. rest] =>
      match first {
        (@lexer.TokenType::Keyword, "ArrayBuffer") =>
          Some((BufferRelatedType::ArrayBuffer, rest))
        (@lexer.TokenType::Keyword, "SharedArrayBuffer") =>
          Some((BufferRelatedType::SharedArrayBuffer, rest))
        (@lexer.TokenType::Keyword, "DataView") =>
          Some((BufferRelatedType::DataView, rest))
        (@lexer.TokenType::Keyword, "Int8Array") =>
          Some((BufferRelatedType::Int8Array, rest))
        (@lexer.TokenType::Keyword, "Int16Array") =>
          Some((BufferRelatedType::Int16Array, rest))
        (@lexer.TokenType::Keyword, "Int32Array") =>
          Some((BufferRelatedType::Int32Array, rest))
        (@lexer.TokenType::Keyword, "Uint8Array") =>
          Some((BufferRelatedType::Uint8Array, rest))
        (@lexer.TokenType::Keyword, "Uint16Array") =>
          Some((BufferRelatedType::Uint16Array, rest))
        (@lexer.TokenType::Keyword, "Uint32Array") =>
          Some((BufferRelatedType::Uint32Array, rest))
        (@lexer.TokenType::Keyword, "Uint8ClampedArray") =>
          Some((BufferRelatedType::Uint8ClampedArray, rest))
        (@lexer.TokenType::Keyword, "BigInt64Array") =>
          Some((BufferRelatedType::BigInt64Array, rest))
        (@lexer.TokenType::Keyword, "BigUint64Array") =>
          Some((BufferRelatedType::BigUint64Array, rest))
        (@lexer.TokenType::Keyword, "Float16Array") =>
          Some((BufferRelatedType::Float16Array, rest))
        (@lexer.TokenType::Keyword, "Float32Array") =>
          Some((BufferRelatedType::Float32Array, rest))
        (@lexer.TokenType::Keyword, "Float64Array") =>
          Some((BufferRelatedType::Float64Array, rest))
        _ => None
      }
    _ => None
  }
}

///|
pub struct UnionType {
  first_union_member_type : UnionMemberType
  second_union_member_type : UnionMemberType
  union_member_types : UnionMemberTypes
}

///|
pub enum UnionMemberType {
  UnionType(UnionType, Null)
  DistinguishableTypeWithExtendedAttributeList(
    DistinguishableType,
    ExtendedAttributeList
  )
}

///|
pub enum UnionMemberTypes {
  Some(UnionMemberType, UnionMemberTypes)
  None
}

///|
pub fn UnionMemberTypes::parse(input : Tokens) -> (UnionMemberTypes, Tokens) {
  if input is [(@lexer.TokenType::Keyword, "or"), .. after_or] &&
    UnionMemberType::parse(after_or)
    is Some((union_member_type, after_union_member_type)) &&
    UnionMemberTypes::parse(after_union_member_type)
    is (union_member_types, rest) {
    (UnionMemberTypes::Some(union_member_type, union_member_types), rest)
  } else {
    (UnionMemberTypes::None, input)
  }
}

///|
pub fn UnionMemberType::parse(input : Tokens) -> (UnionMemberType, Tokens)? {
  if ExtendedAttributeList::parse(input)
    is (extended_attribute_list, after_extended_attribute_list) &&
    DistinguishableType::parse(after_extended_attribute_list)
    is Some((distinguishable_type, rest)) {
    return Some(
      (
        UnionMemberType::DistinguishableTypeWithExtendedAttributeList(
          distinguishable_type, extended_attribute_list,
        ),
        rest,
      ),
    )
  }

  if UnionType::parse(input) is Some((union_type, after_union_type)) &&
    Null::parse(after_union_type) is (null, rest) {
    return Some((UnionMemberType::UnionType(union_type, null), rest))
  }

  return None
}

///|
pub fn UnionType::parse(input : Tokens) -> (UnionType, Tokens)? {
  if input is [(@lexer.TokenType::Punctuation, "("), .. after_parentheses_start] &&
    UnionMemberType::parse(after_parentheses_start)
    is Some(
      (first_union_member_type, [(@lexer.TokenType::Keyword, "or"), .. after_or]
      )
    ) &&
    UnionMemberType::parse(after_or)
    is Some(
      (
        second_union_member_type,
        [
          (@lexer.TokenType::Punctuation, ")"),
          .. after_second_union_member_type,
        ],
      )
    ) &&
    UnionMemberTypes::parse(after_second_union_member_type)
    is (union_member_types, [(@lexer.TokenType::Punctuation, ")"), .. rest]) {
    return Some(
      (
        UnionType::{
          first_union_member_type,
          second_union_member_type,
          union_member_types,
        },
        rest,
      ),
    )
  }

  None
}

///|
pub struct PromiseType {
  type_ : Type
}

///|
pub fn PromiseType::parse(input : Tokens) -> (PromiseType, Tokens)? {
  if input
    is [
      (@lexer.TokenType::Keyword, "Promise"),
      (@lexer.TokenType::Punctuation, "<"),
      .. after_promise_start,
    ] &&
    Type::parse(after_promise_start)
    is Some((type_, [(@lexer.TokenType::Punctuation, ">"), .. rest])) {
    return Some((PromiseType::{ type_, }, rest))
  }

  None
}

///|
pub enum SingleType {
  DistinguishableType(DistinguishableType)
  Any
  PromiseType(PromiseType)
}

///|
pub fn SingleType::parse(input : Tokens) -> (SingleType, Tokens)? {
  if DistinguishableType::parse(input) is Some((distinguishable_type, rest)) {
    return Some((SingleType::DistinguishableType(distinguishable_type), rest))
  }

  if input is [(@lexer.TokenType::Keyword, "any"), .. rest] {
    return Some((SingleType::Any, rest))
  }

  if PromiseType::parse(input) is Some((promise_type, rest)) {
    return Some((SingleType::PromiseType(promise_type), rest))
  }

  return None
}

///|
pub enum ConstType {
  PrimitiveType(PrimitiveType)
  Identifier(StringView)
}

///|
pub fn ConstType::parse(input : Tokens) -> (ConstType, Tokens)? {
  if PrimitiveType::parse(input) is Some((primitive_type, rest)) {
    return Some((ConstType::PrimitiveType(primitive_type), rest))
  }

  if input is [(@lexer.TokenType::Identifier, identifier), .. rest] {
    return Some((ConstType::Identifier(identifier), rest))
  }

  return None
}

///|
pub struct Typedef {
  type_with_extended_attributes : TypeWithExtendedAttributes
  identifier : StringView
}

///|
pub fn Typedef::parse(input : Tokens) -> (Typedef, Tokens)? {
  if input is [(@lexer.TokenType::Keyword, "typedef"), .. after_typedef] &&
    TypeWithExtendedAttributes::parse(after_typedef)
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
    return Some((Typedef::{ type_with_extended_attributes, identifier }, rest))
  }

  None
}
