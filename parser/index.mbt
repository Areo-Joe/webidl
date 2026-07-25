///|
pub enum ExtendedAttributeList {
  Some(ExtendedAttribute, ExtendedAttributes)
  None
} derive(Debug)

///|
pub fn ExtendedAttributeList::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (ExtendedAttributeList, ArrayView[(@lexer.TokenType, StringView)]) {
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
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (ExtendedAttributes, ArrayView[(@lexer.TokenType, StringView)]) {
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
pub fn ExtendedAttribute::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (ExtendedAttribute, ArrayView[(@lexer.TokenType, StringView)])? {
  fn parse_other(
    input : ArrayView[(@lexer.TokenType, StringView)],
  ) -> (ExtendedAttribute, ArrayView[(@lexer.TokenType, StringView)])? {
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
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (ExtendedAttributeRest, ArrayView[(@lexer.TokenType, StringView)]) {
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
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (ExtendedAttributeInner, ArrayView[(@lexer.TokenType, StringView)]) {
  fn parse_other_or_comma(
    input : ArrayView[(@lexer.TokenType, StringView)],
  ) -> (ExtendedAttributeInner, ArrayView[(@lexer.TokenType, StringView)]) {
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
pub fn OtherOrComma::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (OtherOrComma, ArrayView[(@lexer.TokenType, StringView)])? {
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
pub fn Other::parse(
  input : ArrayView[(@lexer.TokenType, StringView)],
) -> (Other, ArrayView[(@lexer.TokenType, StringView)])? {
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
