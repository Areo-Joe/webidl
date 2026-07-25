///|
fn extended_attribute_tokens(input : String) -> Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "IdentifierList and Identifiers parse recursively" {
  assert_true(
    IdentifierList::parse(extended_attribute_tokens("One, Two, Three tail"))
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    Identifiers::parse(extended_attribute_tokens(", One, Two tail"))
    is (
      Identifiers::Some("One", Identifiers::Some("Two", Identifiers::None)),
      [(@lexer.TokenType::Identifier, "tail")],
    ),
  )
  assert_true(
    Identifiers::parse(extended_attribute_tokens("tail"))
    is (Identifiers::None, [(@lexer.TokenType::Identifier, "tail")]),
  )
  assert_true(IdentifierList::parse(extended_attribute_tokens("")) is None)
}

///|
test "IntegerList and Integers parse recursively" {
  assert_true(
    IntegerList::parse(extended_attribute_tokens("1, -2, 0x10 tail"))
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    Integers::parse(extended_attribute_tokens(", 1, -2 tail"))
    is (
      Integers::Some("1", Integers::Some("-2", Integers::None)),
      [(@lexer.TokenType::Identifier, "tail")],
    ),
  )
  assert_true(
    Integers::parse(extended_attribute_tokens("tail"))
    is (Integers::None, [(@lexer.TokenType::Identifier, "tail")]),
  )
  assert_true(IntegerList::parse(extended_attribute_tokens("")) is None)
}

///|
test "extended attribute no-args and argument-list forms parse" {
  assert_true(
    ExtendedAttributeNoArgs::parse(extended_attribute_tokens("Attr tail"))
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    ExtendedAttributeArgList::parse(extended_attribute_tokens("Attr() tail"))
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    ExtendedAttributeArgList::parse(
      extended_attribute_tokens(
        "Attr(DOMString value, optional long count) tail",
      ),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
}

///|
test "extended attribute scalar assignment forms parse" {
  assert_true(
    ExtendedAttributeIdent::parse(extended_attribute_tokens("Attr=Value tail"))
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    ExtendedAttributeString::parse(
      extended_attribute_tokens("Attr=\"value\" tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    ExtendedAttributeInteger::parse(extended_attribute_tokens("Attr=-42 tail"))
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    ExtendedAttributeDecimal::parse(
      extended_attribute_tokens("Attr=-1.5e2 tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    ExtendedAttributeWildcard::parse(extended_attribute_tokens("Attr=* tail"))
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
}

///|
test "extended attribute list assignment forms parse" {
  assert_true(
    ExtendedAttributeIdentList::parse(
      extended_attribute_tokens("Attr=(One, Two, Three) tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    ExtendedAttributeIntegerList::parse(
      extended_attribute_tokens("Attr=(1, -2, 0x10) tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    ExtendedAttributeIdentList::parse(extended_attribute_tokens("Attr=()"))
    is None,
  )
  assert_true(
    ExtendedAttributeIntegerList::parse(extended_attribute_tokens("Attr=()"))
    is None,
  )
}

///|
test "extended attribute named argument-list form parses" {
  assert_true(
    ExtendedAttributeNamedArgList::parse(
      extended_attribute_tokens("Attr=Value() tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    ExtendedAttributeNamedArgList::parse(
      extended_attribute_tokens("Attr=Value(DOMString value) tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
}

///|
test "structured forms reject mismatched terminal kinds" {
  assert_true(
    ExtendedAttributeIdent::parse(extended_attribute_tokens("Attr=1")) is None,
  )
  assert_true(
    ExtendedAttributeString::parse(extended_attribute_tokens("Attr=Value"))
    is None,
  )
  assert_true(
    ExtendedAttributeInteger::parse(extended_attribute_tokens("Attr=1.5"))
    is None,
  )
  assert_true(
    ExtendedAttributeDecimal::parse(extended_attribute_tokens("Attr=1")) is None,
  )
  assert_true(
    ExtendedAttributeWildcard::parse(extended_attribute_tokens("Attr=Value"))
    is None,
  )
  assert_true(
    ExtendedAttributeNamedArgList::parse(
      extended_attribute_tokens("Attr=Value("),
    )
    is None,
  )
}

///|
test "generic extended attribute parser remains available after file move" {
  let (parsed, rest) = ExtendedAttributeList::parse(
    extended_attribute_tokens("[Attr=(One, Two), Other={nested}] tail"),
  )
  assert_true(parsed is ExtendedAttributeList::Some(_, _))
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}
