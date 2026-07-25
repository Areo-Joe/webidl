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
}

///|
pub fn ArgumentNameKeyword::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (ArgumentNameKeyword, ArrayView[(@lexer.TokenType, StringView)])? {
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
}

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
