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
