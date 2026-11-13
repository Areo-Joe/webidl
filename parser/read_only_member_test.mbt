///|
fn read_only_member_tokens(input : String) -> @parser.Tokens {
  (try! @lexer.tokenize(input)).exact_view()
}

///|
test "ReadOnlyMemberRest parses AttributeRest" {
  guard @parser.ReadOnlyMemberRest::parse(
      read_only_member_tokens("attribute DOMString name; tail"),
    )
    is Some((parsed, rest)) else {
    fail("expected attribute member rest to parse")
  }
  assert_true(parsed is @parser.ReadOnlyMemberRest::Attribute(_))
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "ReadOnlyMemberRest parses MaplikeRest" {
  guard @parser.ReadOnlyMemberRest::parse(
      read_only_member_tokens("maplike<DOMString, long>; tail"),
    )
    is Some((parsed, rest)) else {
    fail("expected maplike member rest to parse")
  }
  assert_true(parsed is @parser.ReadOnlyMemberRest::Maplike(_))
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "ReadOnlyMemberRest parses SetlikeRest" {
  guard @parser.ReadOnlyMemberRest::parse(
      read_only_member_tokens("setlike<[Clamp] unsigned long>; tail"),
    )
    is Some((parsed, rest)) else {
    fail("expected setlike member rest to parse")
  }
  assert_true(parsed is @parser.ReadOnlyMemberRest::Setlike(_))
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "ReadOnlyMember requires readonly and a supported member rest" {
  guard @parser.ReadOnlyMember::parse(
      read_only_member_tokens("readonly attribute DOMString name; tail"),
    )
    is Some((_, rest)) else {
    fail("expected readonly member to parse")
  }
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
  assert_true(
    @parser.ReadOnlyMember::parse(
      read_only_member_tokens("attribute DOMString name;"),
    )
    is None,
  )
  assert_true(
    @parser.ReadOnlyMember::parse(
      read_only_member_tokens("readonly iterable<long>;"),
    )
    is None,
  )
}
