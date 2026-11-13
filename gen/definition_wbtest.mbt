///|
test "interface inheritance is resolved after definitions are created" {
  let (definitions, rest) = @parser.parse(
    (try! @lexer.tokenize("interface Child : Parent {}; interface Parent {};")).exact_view(),
  )
  assert_true(rest is [])

  guard Definition::from_parser(definitions)
    is [Interface(child), Interface(parent)] else {
    fail("expected two interfaces")
  }

  assert_true(parent.inheritance is None)
  assert_true(
    child.inheritance is Some(inherited) &&
    name_of_interface(inherited) == name_of_interface(parent),
  )
}

///|
test "interface identifiers are normalized once" {
  let (definitions, rest) = @parser.parse(
    (try! @lexer.tokenize("interface _interface {};")).exact_view(),
  )
  assert_true(rest is [])

  guard Definition::from_parser(definitions) is [Interface(interface)] else {
    fail("expected one interface")
  }

  assert_eq(name_of_interface(interface), "interface")
}
