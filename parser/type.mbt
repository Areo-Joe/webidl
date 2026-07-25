///|
pub enum Type {}

///|
pub fn Type::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (Type, ArrayView[(@lexer.TokenType, StringView)])? {
  ...
}

///|
pub struct TypeWithExtendedAttributes {
  extended_attribute_list : ExtendedAttributeList
  type_ : Type
}

///|
pub fn TypeWithExtendedAttributes::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (TypeWithExtendedAttributes, ArrayView[(@lexer.TokenType, StringView)])? {
  let (extended_attribute_list, after_extended_attribute_list) = ExtendedAttributeList::parse(
    input,
  )

  guard Type::parse(after_extended_attribute_list) is Some((type_, rest)) else {
    return None
  }

  Some((TypeWithExtendedAttributes::{ extended_attribute_list, type_ }, rest))
}

///|
pub enum Null {
  Some
  None
} derive(Debug)

///|
pub fn Null::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (Null, ArrayView[(@lexer.TokenType, StringView)]) {
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
pub fn StringType::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (StringType, ArrayView[(@lexer.TokenType, StringView)])? {
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
pub fn OptionalLong::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (OptionalLong, ArrayView[(@lexer.TokenType, StringView)]) {
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
pub fn IntegerType::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (IntegerType, ArrayView[(@lexer.TokenType, StringView)])? {
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
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (UnsignedIntegerType, ArrayView[(@lexer.TokenType, StringView)])? {
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
pub fn FloatType::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (FloatType, ArrayView[(@lexer.TokenType, StringView)])? {
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
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (UnrestrictedFloatType, ArrayView[(@lexer.TokenType, StringView)])? {
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
pub fn PrimitiveType::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (PrimitiveType, ArrayView[(@lexer.TokenType, StringView)])? {
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
pub fn BufferRelatedType::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (BufferRelatedType, ArrayView[(@lexer.TokenType, StringView)])? {
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
