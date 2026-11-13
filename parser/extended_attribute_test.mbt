///|
fn extended_attribute_tokens(input : String) -> @parser.Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "IdentifierList and Identifiers parse recursively" {
  assert_true(
    @parser.IdentifierList::parse(
      extended_attribute_tokens("One, Two, Three tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    @parser.Identifiers::parse(extended_attribute_tokens(", One, Two tail"))
    is (
      @parser.Identifiers::Some(
        "One",
        @parser.Identifiers::Some("Two", @parser.Identifiers::None)
      ),
      [(@lexer.TokenType::Identifier, "tail")],
    ),
  )
  assert_true(
    @parser.Identifiers::parse(extended_attribute_tokens("tail"))
    is (@parser.Identifiers::None, [(@lexer.TokenType::Identifier, "tail")]),
  )
  assert_true(
    @parser.IdentifierList::parse(extended_attribute_tokens("")) is None,
  )
}

///|
test "IntegerList and Integers parse recursively" {
  assert_true(
    @parser.IntegerList::parse(extended_attribute_tokens("1, -2, 0x10 tail"))
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    @parser.Integers::parse(extended_attribute_tokens(", 1, -2 tail"))
    is (
      @parser.Integers::Some(
        "1",
        @parser.Integers::Some("-2", @parser.Integers::None)
      ),
      [(@lexer.TokenType::Identifier, "tail")],
    ),
  )
  assert_true(
    @parser.Integers::parse(extended_attribute_tokens("tail"))
    is (@parser.Integers::None, [(@lexer.TokenType::Identifier, "tail")]),
  )
  assert_true(@parser.IntegerList::parse(extended_attribute_tokens("")) is None)
}

///|
test "extended attribute no-args and argument-list forms parse" {
  assert_true(
    @parser.ExtendedAttributeNoArgs::parse(
      extended_attribute_tokens("Attr tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    @parser.ExtendedAttributeArgList::parse(
      extended_attribute_tokens("Attr() tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    @parser.ExtendedAttributeArgList::parse(
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
    @parser.ExtendedAttributeIdent::parse(
      extended_attribute_tokens("Attr=Value tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    @parser.ExtendedAttributeString::parse(
      extended_attribute_tokens("Attr=\"value\" tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    @parser.ExtendedAttributeInteger::parse(
      extended_attribute_tokens("Attr=-42 tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    @parser.ExtendedAttributeDecimal::parse(
      extended_attribute_tokens("Attr=-1.5e2 tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    @parser.ExtendedAttributeWildcard::parse(
      extended_attribute_tokens("Attr=* tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
}

///|
test "extended attribute list assignment forms parse" {
  assert_true(
    @parser.ExtendedAttributeIdentList::parse(
      extended_attribute_tokens("Attr=(One, Two, Three) tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    @parser.ExtendedAttributeIntegerList::parse(
      extended_attribute_tokens("Attr=(1, -2, 0x10) tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    @parser.ExtendedAttributeIdentList::parse(
      extended_attribute_tokens("Attr=()"),
    )
    is None,
  )
  assert_true(
    @parser.ExtendedAttributeIntegerList::parse(
      extended_attribute_tokens("Attr=()"),
    )
    is None,
  )
}

///|
test "extended attribute named argument-list form parses" {
  assert_true(
    @parser.ExtendedAttributeNamedArgList::parse(
      extended_attribute_tokens("Attr=Value() tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
  assert_true(
    @parser.ExtendedAttributeNamedArgList::parse(
      extended_attribute_tokens("Attr=Value(DOMString value) tail"),
    )
    is Some((_, [(@lexer.TokenType::Identifier, "tail")])),
  )
}

///|
test "structured forms reject mismatched terminal kinds" {
  assert_true(
    @parser.ExtendedAttributeIdent::parse(extended_attribute_tokens("Attr=1"))
    is None,
  )
  assert_true(
    @parser.ExtendedAttributeString::parse(
      extended_attribute_tokens("Attr=Value"),
    )
    is None,
  )
  assert_true(
    @parser.ExtendedAttributeInteger::parse(
      extended_attribute_tokens("Attr=1.5"),
    )
    is None,
  )
  assert_true(
    @parser.ExtendedAttributeDecimal::parse(extended_attribute_tokens("Attr=1"))
    is None,
  )
  assert_true(
    @parser.ExtendedAttributeWildcard::parse(
      extended_attribute_tokens("Attr=Value"),
    )
    is None,
  )
  assert_true(
    @parser.ExtendedAttributeNamedArgList::parse(
      extended_attribute_tokens("Attr=Value("),
    )
    is None,
  )
}

///|
test "ExtendedAttribute classifies each of the ten specified forms" {
  assert_true(
    @parser.ExtendedAttribute::parse(extended_attribute_tokens("Replaceable"))
    is Some((@parser.ExtendedAttribute::NoArgs(_), [])),
  )
  assert_true(
    @parser.ExtendedAttribute::parse(
      extended_attribute_tokens("Constructor(double x)"),
    )
    is Some((@parser.ExtendedAttribute::ArgList(_), [])),
  )
  assert_true(
    @parser.ExtendedAttribute::parse(
      extended_attribute_tokens("LegacyFactoryFunction=Image(DOMString src)"),
    )
    is Some((@parser.ExtendedAttribute::NamedArgList(_), [])),
  )
  assert_true(
    @parser.ExtendedAttribute::parse(
      extended_attribute_tokens("PutForwards=name"),
    )
    is Some((@parser.ExtendedAttribute::Ident(_), [])),
  )
  assert_true(
    @parser.ExtendedAttribute::parse(
      extended_attribute_tokens("Reflect=\"popover\""),
    )
    is Some((@parser.ExtendedAttribute::String(_), [])),
  )
  assert_true(
    @parser.ExtendedAttribute::parse(
      extended_attribute_tokens("ReflectDefault=2"),
    )
    is Some((@parser.ExtendedAttribute::Integer(_), [])),
  )
  assert_true(
    @parser.ExtendedAttribute::parse(
      extended_attribute_tokens("ReflectDefault=2.0"),
    )
    is Some((@parser.ExtendedAttribute::Decimal(_), [])),
  )
  assert_true(
    @parser.ExtendedAttribute::parse(
      extended_attribute_tokens("ReflectRange=(2, 600)"),
    )
    is Some((@parser.ExtendedAttribute::IntegerList(_), [])),
  )
  assert_true(
    @parser.ExtendedAttribute::parse(
      extended_attribute_tokens("Exposed=(Window,Worker)"),
    )
    is Some((@parser.ExtendedAttribute::IdentList(_), [])),
  )
  assert_true(
    @parser.ExtendedAttribute::parse(extended_attribute_tokens("Exposed=*"))
    is Some((@parser.ExtendedAttribute::Wildcard(_), [])),
  )
}

///|
test "ExtendedAttribute rejects shapes outside the ten specified forms" {
  assert_true(
    @parser.ExtendedAttribute::parse(extended_attribute_tokens("")) is None,
  )
  assert_true(
    @parser.ExtendedAttribute::parse(extended_attribute_tokens("{nested}"))
    is None,
  )
  assert_true(
    @parser.ExtendedAttribute::parse(extended_attribute_tokens("=Value"))
    is None,
  )
  let (parsed, rest) = @parser.ExtendedAttributeList::parse(
    extended_attribute_tokens("[Attr=(One, Two), Other={nested}] tail"),
  )
  assert_true(parsed is @parser.ExtendedAttributeList::None)
  assert_true(rest is [(@lexer.TokenType::Punctuation, "["), ..])
}

///|
test "ExtendedAttributeList classifies every entry it collects" {
  let (parsed, rest) = @parser.ExtendedAttributeList::parse(
    extended_attribute_tokens("[Exposed=(Window,Worker), SecureContext] tail"),
  )
  assert_true(
    parsed
    is @parser.ExtendedAttributeList::Some(
      @parser.ExtendedAttribute::IdentList(_),
      @parser.ExtendedAttributes::Some(
        @parser.ExtendedAttribute::NoArgs(_),
        @parser.ExtendedAttributes::None
      )
    ),
  )
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}
