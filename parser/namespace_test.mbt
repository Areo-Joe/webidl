///|
fn namespace_tokens(input : String) -> Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "NamespaceMember parses every alternative" {
  assert_true(
    NamespaceMember::parse(namespace_tokens("long operation(); tail"))
    is Some((NamespaceMember::RegularOperation(_), [(_, "tail")])),
  )
  assert_true(
    NamespaceMember::parse(
      namespace_tokens("readonly attribute DOMString name; tail"),
    )
    is Some((NamespaceMember::ReadOnlyAttribute(_), [(_, "tail")])),
  )
  assert_true(
    NamespaceMember::parse(namespace_tokens("const long value = 1; tail"))
    is Some((NamespaceMember::Const(_), [(_, "tail")])),
  )
}

///|
test "NamespaceMembers parses epsilon without consuming input" {
  assert_true(
    NamespaceMembers::parse(namespace_tokens("tail"))
    is (NamespaceMembers::None, [(_, "tail")]),
  )
}

///|
test "Namespace parses an empty body" {
  assert_true(
    Namespace::parse(namespace_tokens("namespace Example {}; tail"))
    is Some((_, [(_, "tail")])),
  )
}

///|
test "Namespace parses recursive attributed members" {
  assert_true(
    Namespace::parse(
      namespace_tokens(
        "namespace Example { [Clamp] readonly attribute DOMString name; long operation(); const long value = 1; }; tail",
      ),
    )
    is Some((_, [(_, "tail")])),
  )
}

///|
test "Namespace rejects unsupported and malformed members" {
  assert_true(
    Namespace::parse(
      namespace_tokens("namespace Example { attribute DOMString name; };"),
    )
    is None,
  )
  assert_true(
    Namespace::parse(
      namespace_tokens("namespace Example { getter long item(); };"),
    )
    is None,
  )
  assert_true(
    Namespace::parse(
      namespace_tokens("namespace Example { const long value = 1;"),
    )
    is None,
  )
  assert_true(
    Namespace::parse(namespace_tokens("namespace Example {}")) is None,
  )
}
