///|
fn parse_extended_attribute_inner(
  input : String,
) -> (ExtendedAttributeInner, ArrayView[(@lexer.TokenType, StringView)]) {
  ExtendedAttributeInner::parse((try! @lexer.tokenize(input)).view())
}

///|
test "ExtendedAttributeInner parses empty input" {
  let (parsed, rest) = parse_extended_attribute_inner("")
  assert_true(parsed is ExtendedAttributeInner::None)
  assert_eq(rest.length(), 0)
}

///|
test "ExtendedAttributeInner parses OtherOrComma tokens" {
  let (parsed, rest) = parse_extended_attribute_inner("Foo, Bar")
  assert_true(
    parsed
    is ExtendedAttributeInner::OtherOrComma(
      OtherOrComma::Other(Other::Identifier("Foo")),
      ExtendedAttributeInner::OtherOrComma(
        OtherOrComma::Comma,
        ExtendedAttributeInner::OtherOrComma(
          OtherOrComma::Other(Other::Identifier("Bar")),
          ExtendedAttributeInner::None
        )
      )
    ),
  )
  assert_eq(rest.length(), 0)
}

///|
test "ExtendedAttributeInner parses nested delimiters and following tokens" {
  let (parsed, rest) = parse_extended_attribute_inner("(foo, [bar]) tail")
  assert_true(
    parsed
    is ExtendedAttributeInner::Parentheses(
      ExtendedAttributeInner::OtherOrComma(
        OtherOrComma::Other(Other::Identifier("foo")),
        ExtendedAttributeInner::OtherOrComma(
          OtherOrComma::Comma,
          ExtendedAttributeInner::Brackets(
            ExtendedAttributeInner::OtherOrComma(
              OtherOrComma::Other(Other::Identifier("bar")),
              ExtendedAttributeInner::None
            ),
            ExtendedAttributeInner::None
          )
        )
      ),
      ExtendedAttributeInner::OtherOrComma(
        OtherOrComma::Other(Other::Identifier("tail")),
        ExtendedAttributeInner::None
      )
    ),
  )
  assert_eq(rest.length(), 0)
}

///|
test "ExtendedAttributeInner leaves an unclosed delimiter for its caller" {
  let (parsed, rest) = parse_extended_attribute_inner("(foo")
  assert_true(parsed is ExtendedAttributeInner::None)
  assert_true(rest is [(@lexer.TokenType::Punctuation, "("), ..])
}

///|
test "ExtendedAttributeInner leaves a closing delimiter for its caller" {
  let (parsed, rest) = parse_extended_attribute_inner(")")
  assert_true(parsed is ExtendedAttributeInner::None)
  assert_true(rest is [(@lexer.TokenType::Punctuation, ")")])
}
