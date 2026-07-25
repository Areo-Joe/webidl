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
