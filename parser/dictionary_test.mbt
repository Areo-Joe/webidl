///|
fn dictionary_tokens(input : String) -> Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "Inheritance parses an identifier or epsilon" {
  assert_true(
    Inheritance::parse(dictionary_tokens(": Base tail"))
    is (Inheritance::Some("Base"), [(_, "tail")]),
  )
  assert_true(
    Inheritance::parse(dictionary_tokens("tail"))
    is (Inheritance::None, [(_, "tail")]),
  )
  assert_true(
    Inheritance::parse(dictionary_tokens(":"))
    is (Inheritance::None, [(@lexer.TokenType::Punctuation, ":")]),
  )
}

///|
test "DictionaryMemberRest parses required and optional members" {
  assert_true(
    DictionaryMemberRest::parse(
      dictionary_tokens("required [Clamp] unsigned long count; tail"),
    )
    is Some((DictionaryMemberRest::Required(_, "count"), [(_, "tail")])),
  )
  assert_true(
    DictionaryMemberRest::parse(
      dictionary_tokens("DOMString label = \"default\"; tail"),
    )
    is Some(
      (
        DictionaryMemberRest::Optional(_, "label", Default::Some(_)),
        [(_, "tail")],
      )
    ),
  )
  assert_true(
    DictionaryMemberRest::parse(dictionary_tokens("long count; tail"))
    is Some(
      (DictionaryMemberRest::Optional(_, "count", Default::None), [(_, "tail")])
    ),
  )
}

///|
test "DictionaryMember parses its extended attributes" {
  assert_true(
    DictionaryMember::parse(
      dictionary_tokens("[Clamp] required unsigned long count; tail"),
    )
    is Some((_, [(_, "tail")])),
  )
}

///|
test "DictionaryMembers parses epsilon without consuming input" {
  assert_true(
    DictionaryMembers::parse(dictionary_tokens("tail"))
    is (DictionaryMembers::None, [(_, "tail")]),
  )
}

///|
test "Dictionary parses inheritance and recursive members" {
  assert_true(
    Dictionary::parse(
      dictionary_tokens(
        "dictionary Options : Base { [Clamp] required unsigned long count; DOMString label = \"default\"; }; tail",
      ),
    )
    is Some((_, [(_, "tail")])),
  )
  assert_true(
    Dictionary::parse(dictionary_tokens("dictionary Empty {}; tail"))
    is Some((_, [(_, "tail")])),
  )
}

///|
test "Dictionary rejects incomplete members and delimiters" {
  assert_true(
    Dictionary::parse(
      dictionary_tokens("dictionary Options { required long count };"),
    )
    is None,
  )
  assert_true(
    Dictionary::parse(dictionary_tokens("dictionary Options { long count; }"))
    is None,
  )
  assert_true(Dictionary::parse(dictionary_tokens("dictionary {};")) is None)
}
