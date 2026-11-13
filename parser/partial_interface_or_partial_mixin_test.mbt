///|
fn parse_partial_interface_or_partial_mixin(
  input : String,
) -> (@parser.PartialInterfaceOrPartialMixin, @parser.Tokens)? {
  @parser.PartialInterfaceOrPartialMixin::parse(
    (try! @lexer.tokenize(input)).exact_view(),
  )
}

///|
test "PartialInterfaceOrPartialMixin parses PartialInterfaceRest" {
  assert_true(
    parse_partial_interface_or_partial_mixin(
      "Example { attribute DOMString name; }; tail",
    )
    is Some(
      (
        @parser.PartialInterfaceOrPartialMixin::PartialInterfaceRest(_),
        [(_, "tail")],
      )
    ),
  )
}

///|
test "PartialInterfaceOrPartialMixin parses MixinRest" {
  assert_true(
    parse_partial_interface_or_partial_mixin(
      "mixin Example { readonly attribute DOMString name; }; tail",
    )
    is Some(
      (@parser.PartialInterfaceOrPartialMixin::MixinRest(_), [(_, "tail")])
    ),
  )
}

///|
test "PartialInterfaceOrPartialMixin rejects other productions" {
  assert_true(
    parse_partial_interface_or_partial_mixin("interface Example {};") is None,
  )
  assert_true(
    parse_partial_interface_or_partial_mixin("mixin Example {}") is None,
  )
}
