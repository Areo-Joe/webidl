///|
fn partial_tokens(input : String) -> @parser.Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "PartialDefinition parses partial interface and mixin bodies" {
  assert_true(
    @parser.PartialDefinition::parse(
      partial_tokens("interface Example { attribute DOMString name; }; tail"),
    )
    is Some((@parser.PartialDefinition::Interface(_), [(_, "tail")])),
  )
  assert_true(
    @parser.PartialDefinition::parse(
      partial_tokens(
        "interface mixin Example { readonly attribute DOMString name; }; tail",
      ),
    )
    is Some((@parser.PartialDefinition::Interface(_), [(_, "tail")])),
  )
}

///|
test "PartialDefinition parses dictionary and namespace bodies" {
  assert_true(
    @parser.PartialDefinition::parse(
      partial_tokens("dictionary Options { DOMString label; }; tail"),
    )
    is Some((@parser.PartialDefinition::Dictionary(_), [(_, "tail")])),
  )
  assert_true(
    @parser.PartialDefinition::parse(
      partial_tokens("namespace Example { const long value = 1; }; tail"),
    )
    is Some((@parser.PartialDefinition::Namespace(_), [(_, "tail")])),
  )
}

///|
test "Partial requires the partial keyword" {
  assert_true(
    @parser.Partial::parse(partial_tokens("partial interface Example {}; tail"))
    is Some((_, [(_, "tail")])),
  )
  assert_true(
    @parser.Partial::parse(
      partial_tokens("partial dictionary Options {}; tail"),
    )
    is Some((_, [(_, "tail")])),
  )
  assert_true(
    @parser.Partial::parse(partial_tokens("partial namespace Example {}; tail"))
    is Some((_, [(_, "tail")])),
  )
  assert_true(
    @parser.Partial::parse(partial_tokens("interface Example {};")) is None,
  )
  assert_true(
    @parser.Partial::parse(partial_tokens("partial enum Example {};")) is None,
  )
}
