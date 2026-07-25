///|
fn read_only_member_tokens(input : String) -> Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "ReadOnlyMemberRest parses AttributeRest" {
  guard ReadOnlyMemberRest::parse(
      read_only_member_tokens("attribute DOMString name; tail"),
    )
    is Some((parsed, rest)) else {
    fail("expected attribute member rest to parse")
  }
  assert_true(parsed is ReadOnlyMemberRest::Attribute(_))
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "ReadOnlyMemberRest parses MaplikeRest" {
  guard ReadOnlyMemberRest::parse(
      read_only_member_tokens("maplike<DOMString, long>; tail"),
    )
    is Some((parsed, rest)) else {
    fail("expected maplike member rest to parse")
  }
  assert_true(parsed is ReadOnlyMemberRest::Maplike(_))
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "ReadOnlyMemberRest parses SetlikeRest" {
  guard ReadOnlyMemberRest::parse(
      read_only_member_tokens("setlike<[Clamp] unsigned long>; tail"),
    )
    is Some((parsed, rest)) else {
    fail("expected setlike member rest to parse")
  }
  assert_true(parsed is ReadOnlyMemberRest::Setlike(_))
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "ReadOnlyMember requires readonly and a supported member rest" {
  guard ReadOnlyMember::parse(
      read_only_member_tokens("readonly attribute DOMString name; tail"),
    )
    is Some((_, rest)) else {
    fail("expected readonly member to parse")
  }
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
  assert_true(
    ReadOnlyMember::parse(read_only_member_tokens("attribute DOMString name;"))
    is None,
  )
  assert_true(
    ReadOnlyMember::parse(read_only_member_tokens("readonly iterable<long>;"))
    is None,
  )
}
