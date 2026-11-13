///|
fn dictionary_tokens(input : String) -> @parser.Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "Inheritance parses an identifier or epsilon" {
  assert_true(
    @parser.Inheritance::parse(dictionary_tokens(": Base tail"))
    is (@parser.Inheritance::Some("Base"), [(_, "tail")]),
  )
  assert_true(
    @parser.Inheritance::parse(dictionary_tokens("tail"))
    is (@parser.Inheritance::None, [(_, "tail")]),
  )
  assert_true(
    @parser.Inheritance::parse(dictionary_tokens(":"))
    is (@parser.Inheritance::None, [(@lexer.TokenType::Punctuation, ":")]),
  )
}

///|
test "DictionaryMemberRest parses required and optional members" {
  assert_true(
    @parser.DictionaryMemberRest::parse(
      dictionary_tokens("required [Clamp] unsigned long count; tail"),
    )
    is Some((@parser.DictionaryMemberRest::Required(_, "count"), [(_, "tail")])),
  )
  assert_true(
    @parser.DictionaryMemberRest::parse(
      dictionary_tokens("DOMString label = \"default\"; tail"),
    )
    is Some(
      (
        @parser.DictionaryMemberRest::Optional(
          _,
          "label",
          @parser.Default::Some(_)
        ),
        [(_, "tail")],
      )
    ),
  )
  assert_true(
    @parser.DictionaryMemberRest::parse(dictionary_tokens("long count; tail"))
    is Some(
      (
        @parser.DictionaryMemberRest::Optional(
          _,
          "count",
          @parser.Default::None
        ),
        [(_, "tail")],
      )
    ),
  )
}

///|
test "DictionaryMember parses its extended attributes" {
  assert_true(
    @parser.DictionaryMember::parse(
      dictionary_tokens("[Clamp] required unsigned long count; tail"),
    )
    is Some((_, [(_, "tail")])),
  )
}

///|
test "DictionaryMembers parses epsilon without consuming input" {
  assert_true(
    @parser.DictionaryMembers::parse(dictionary_tokens("tail"))
    is (@parser.DictionaryMembers::None, [(_, "tail")]),
  )
}

///|
test "Dictionary parses inheritance and recursive members" {
  assert_true(
    @parser.Dictionary::parse(
      dictionary_tokens(
        "dictionary Options : Base { [Clamp] required unsigned long count; DOMString label = \"default\"; }; tail",
      ),
    )
    is Some((_, [(_, "tail")])),
  )
  assert_true(
    @parser.Dictionary::parse(dictionary_tokens("dictionary Empty {}; tail"))
    is Some((_, [(_, "tail")])),
  )
}

///|
test "Dictionary rejects incomplete members and delimiters" {
  assert_true(
    @parser.Dictionary::parse(
      dictionary_tokens("dictionary Options { required long count };"),
    )
    is None,
  )
  assert_true(
    @parser.Dictionary::parse(
      dictionary_tokens("dictionary Options { long count; }"),
    )
    is None,
  )
  assert_true(
    @parser.Dictionary::parse(dictionary_tokens("dictionary {};")) is None,
  )
}
