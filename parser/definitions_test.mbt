///|
fn definition_tokens(input : String) -> @parser.Tokens {
  (try! @lexer.tokenize(input)).exact_view()
}

///|
test "Definition parses every alternative" {
  assert_true(
    @parser.Definition::parse(definition_tokens("interface Example {}; tail"))
    is Some((@parser.Definition::CallbackOrInterfaceOrMixin(_), [(_, "tail")])),
  )
  assert_true(
    @parser.Definition::parse(definition_tokens("namespace Example {}; tail"))
    is Some((@parser.Definition::Namespace(_), [(_, "tail")])),
  )
  assert_true(
    @parser.Definition::parse(
      definition_tokens("partial interface Example {}; tail"),
    )
    is Some((@parser.Definition::Partial(_), [(_, "tail")])),
  )
  assert_true(
    @parser.Definition::parse(definition_tokens("dictionary Options {}; tail"))
    is Some((@parser.Definition::Dictionary(_), [(_, "tail")])),
  )
  assert_true(
    @parser.Definition::parse(definition_tokens("enum Mode { \"one\" }; tail"))
    is Some((@parser.Definition::Enum(_), [(_, "tail")])),
  )
  assert_true(
    @parser.Definition::parse(definition_tokens("typedef DOMString Name; tail"))
    is Some((@parser.Definition::Typedef(_), [(_, "tail")])),
  )
  assert_true(
    @parser.Definition::parse(
      definition_tokens("Example includes Shared; tail"),
    )
    is Some((@parser.Definition::IncludesStatement(_), [(_, "tail")])),
  )
}

///|
test "Definitions parses a mixed attributed document" {
  let (parsed, rest) = @parser.Definitions::parse(
    definition_tokens(
      "[Exposed=Window] interface Example {}; dictionary Options { DOMString label; }; enum Mode { \"one\", \"two\" }; typedef DOMString Name; Example includes Shared; tail",
    ),
  )
  assert_true(
    parsed
    is @parser.Definitions::Some(
      @parser.ExtendedAttributeList::Some(_, _),
      _,
      _
    ),
  )
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "Definitions parses epsilon without consuming input" {
  assert_true(
    @parser.Definitions::parse(definition_tokens("tail"))
    is (@parser.Definitions::None, [(_, "tail")]),
  )
}

///|
test "Definitions leaves malformed definitions untouched" {
  assert_true(
    @parser.Definitions::parse(
      definition_tokens("[Exposed] interface Example {}"),
    )
    is (@parser.Definitions::None, [(@lexer.TokenType::Punctuation, "["), ..]),
  )
  assert_true(
    @parser.Definition::parse(definition_tokens("const long value = 1;"))
    is None,
  )
}
