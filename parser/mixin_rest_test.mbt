///|
fn mixin_tokens(input : String) -> Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "MixinMembers parses epsilon without consuming input" {
  let input = mixin_tokens("tail")
  let (parsed, rest) = MixinMembers::parse(input)
  assert_true(parsed is MixinMembers::None)
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "MixinRest parses an empty body" {
  guard MixinRest::parse(mixin_tokens("mixin Example {}; tail"))
    is Some((_, rest)) else {
    fail("expected empty mixin rest to parse")
  }
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "MixinRest parses recursive attributed members" {
  guard MixinRest::parse(
      mixin_tokens(
        "mixin Example { [Clamp] readonly attribute DOMString name; long operation(); }; tail",
      ),
    )
    is Some((_, rest)) else {
    fail("expected populated mixin rest to parse")
  }
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "MixinRest requires its keyword, identifier, and delimiters" {
  assert_true(MixinRest::parse(mixin_tokens("Example {};")) is None)
  assert_true(MixinRest::parse(mixin_tokens("mixin interface {};")) is None)
  assert_true(
    MixinRest::parse(mixin_tokens("mixin Example { const long value = 1;"))
    is None,
  )
  assert_true(MixinRest::parse(mixin_tokens("mixin Example {}")) is None)
}
