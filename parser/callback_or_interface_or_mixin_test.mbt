///|
fn parse_callback_or_interface_or_mixin(
  input : String,
) -> (CallbackOrInterfaceOrMixin, Tokens)? {
  CallbackOrInterfaceOrMixin::parse((try! @lexer.tokenize(input)).view())
}

///|
test "InterfaceMember parses partial members and constructors" {
  assert_true(
    InterfaceMember::parse(
      (try! @lexer.tokenize("attribute DOMString name; tail")).view(),
    )
    is Some((InterfaceMember::PartialInterfaceMember(_), [(_, "tail")])),
  )
  assert_true(
    InterfaceMember::parse((try! @lexer.tokenize("constructor(); tail")).view())
    is Some((InterfaceMember::Constructor(_), [(_, "tail")])),
  )
}

///|
test "InterfaceRest parses inheritance and recursive members" {
  assert_true(
    InterfaceRest::parse(
      (try! @lexer.tokenize(
        "Example : Base { [Clamp] constructor(); attribute DOMString name; }; tail",
      )).view(),
    )
    is Some((_, [(_, "tail")])),
  )
  assert_true(
    InterfaceRest::parse((try! @lexer.tokenize("Empty {}; tail")).view())
    is Some((_, [(_, "tail")])),
  )
}

///|
test "CallbackOrInterfaceOrMixin parses callback alternatives" {
  assert_true(
    parse_callback_or_interface_or_mixin("callback Handler = long(); tail")
    is Some((CallbackOrInterfaceOrMixin::Callback(_), [(_, "tail")])),
  )
  assert_true(
    parse_callback_or_interface_or_mixin(
      "callback interface Handler { long invoke(); }; tail",
    )
    is Some((CallbackOrInterfaceOrMixin::Callback(_), [(_, "tail")])),
  )
}

///|
test "CallbackOrInterfaceOrMixin parses interfaces and mixins" {
  assert_true(
    parse_callback_or_interface_or_mixin(
      "interface Example { constructor(); }; tail",
    )
    is Some((CallbackOrInterfaceOrMixin::Interface(_), [(_, "tail")])),
  )
  assert_true(
    parse_callback_or_interface_or_mixin(
      "interface mixin Example { readonly attribute DOMString name; }; tail",
    )
    is Some((CallbackOrInterfaceOrMixin::Interface(_), [(_, "tail")])),
  )
}

///|
test "CallbackOrInterfaceOrMixin rejects missing and malformed prefixes" {
  assert_true(parse_callback_or_interface_or_mixin("Handler = long();") is None)
  assert_true(
    parse_callback_or_interface_or_mixin("interface Example {}") is None,
  )
  assert_true(
    parse_callback_or_interface_or_mixin("callback interface Example {}")
    is None,
  )
}
