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
test "ExtendedAttribute classifies each of the ten specified forms" {
  assert_true(
    ExtendedAttribute::parse(extended_attribute_tokens("Replaceable"))
    is Some((ExtendedAttribute::NoArgs(_), [])),
  )
  assert_true(
    ExtendedAttribute::parse(extended_attribute_tokens("Constructor(double x)"))
    is Some((ExtendedAttribute::ArgList(_), [])),
  )
  assert_true(
    ExtendedAttribute::parse(
      extended_attribute_tokens("LegacyFactoryFunction=Image(DOMString src)"),
    )
    is Some((ExtendedAttribute::NamedArgList(_), [])),
  )
  assert_true(
    ExtendedAttribute::parse(extended_attribute_tokens("PutForwards=name"))
    is Some((ExtendedAttribute::Ident(_), [])),
  )
  assert_true(
    ExtendedAttribute::parse(extended_attribute_tokens("Reflect=\"popover\""))
    is Some((ExtendedAttribute::String(_), [])),
  )
  assert_true(
    ExtendedAttribute::parse(extended_attribute_tokens("ReflectDefault=2"))
    is Some((ExtendedAttribute::Integer(_), [])),
  )
  assert_true(
    ExtendedAttribute::parse(extended_attribute_tokens("ReflectDefault=2.0"))
    is Some((ExtendedAttribute::Decimal(_), [])),
  )
  assert_true(
    ExtendedAttribute::parse(extended_attribute_tokens("ReflectRange=(2, 600)"))
    is Some((ExtendedAttribute::IntegerList(_), [])),
  )
  assert_true(
    ExtendedAttribute::parse(
      extended_attribute_tokens("Exposed=(Window,Worker)"),
    )
    is Some((ExtendedAttribute::IdentList(_), [])),
  )
  assert_true(
    ExtendedAttribute::parse(extended_attribute_tokens("Exposed=*"))
    is Some((ExtendedAttribute::Wildcard(_), [])),
  )
}

///|
test "ExtendedAttribute rejects shapes outside the ten specified forms" {
  assert_true(ExtendedAttribute::parse(extended_attribute_tokens("")) is None)
  assert_true(
    ExtendedAttribute::parse(extended_attribute_tokens("{nested}")) is None,
  )
  assert_true(
    ExtendedAttribute::parse(extended_attribute_tokens("=Value")) is None,
  )
  let (parsed, rest) = ExtendedAttributeList::parse(
    extended_attribute_tokens("[Attr=(One, Two), Other={nested}] tail"),
  )
  assert_true(parsed is ExtendedAttributeList::None)
  assert_true(rest is [(@lexer.TokenType::Punctuation, "["), ..])
}

///|
test "ExtendedAttributeList classifies every entry it collects" {
  let (parsed, rest) = ExtendedAttributeList::parse(
    extended_attribute_tokens("[Exposed=(Window,Worker), SecureContext] tail"),
  )
  assert_true(
    parsed
    is ExtendedAttributeList::Some(
      ExtendedAttribute::IdentList(_),
      ExtendedAttributes::Some(
        ExtendedAttribute::NoArgs(_),
        ExtendedAttributes::None
      )
    ),
  )
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}
