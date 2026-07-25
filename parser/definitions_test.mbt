///|
fn definition_tokens(input : String) -> Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "Definition parses every alternative" {
  assert_true(
    Definition::parse(definition_tokens("interface Example {}; tail"))
    is Some((Definition::CallbackOrInterfaceOrMixin(_), [(_, "tail")])),
  )
  assert_true(
    Definition::parse(definition_tokens("namespace Example {}; tail"))
    is Some((Definition::Namespace(_), [(_, "tail")])),
  )
  assert_true(
    Definition::parse(definition_tokens("partial interface Example {}; tail"))
    is Some((Definition::Partial(_), [(_, "tail")])),
  )
  assert_true(
    Definition::parse(definition_tokens("dictionary Options {}; tail"))
    is Some((Definition::Dictionary(_), [(_, "tail")])),
  )
  assert_true(
    Definition::parse(definition_tokens("enum Mode { \"one\" }; tail"))
    is Some((Definition::Enum(_), [(_, "tail")])),
  )
  assert_true(
    Definition::parse(definition_tokens("typedef DOMString Name; tail"))
    is Some((Definition::Typedef(_), [(_, "tail")])),
  )
  assert_true(
    Definition::parse(definition_tokens("Example includes Shared; tail"))
    is Some((Definition::IncludesStatement(_), [(_, "tail")])),
  )
}

///|
test "Definitions parses a mixed attributed document" {
  let (parsed, rest) = Definitions::parse(
    definition_tokens(
      "[Exposed=Window] interface Example {}; dictionary Options { DOMString label; }; enum Mode { \"one\", \"two\" }; typedef DOMString Name; Example includes Shared; tail",
    ),
  )
  assert_true(
    parsed is Definitions::Some(ExtendedAttributeList::Some(_, _), _, _),
  )
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "Definitions parses epsilon without consuming input" {
  assert_true(
    Definitions::parse(definition_tokens("tail"))
    is (Definitions::None, [(_, "tail")]),
  )
}

///|
test "Definitions leaves malformed definitions untouched" {
  assert_true(
    Definitions::parse(definition_tokens("[Exposed] interface Example {}"))
    is (Definitions::None, [(@lexer.TokenType::Punctuation, "["), ..]),
  )
  assert_true(
    Definition::parse(definition_tokens("const long value = 1;")) is None,
  )
}
