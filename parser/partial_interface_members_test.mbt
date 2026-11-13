///|
fn parse_partial_interface_members(
  input : String,
) -> (@parser.PartialInterfaceMembers, @parser.Tokens) {
  @parser.PartialInterfaceMembers::parse(
    (try! @lexer.tokenize(input)).exact_view(),
  )
}

///|
test "PartialInterfaceMembers parses epsilon without consuming input" {
  let (parsed, rest) = parse_partial_interface_members("tail")
  assert_true(parsed is @parser.PartialInterfaceMembers::None)
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "PartialInterfaceMembers parses attributed and plain members recursively" {
  let (parsed, rest) = parse_partial_interface_members(
    "[Clamp] attribute DOMString name; const long value = 1; tail",
  )
  assert_true(
    parsed
    is @parser.PartialInterfaceMembers::Some(
      @parser.ExtendedAttributeList::Some(_, _),
      @parser.PartialInterfaceMember::ReadWriteAttribute(_),
      @parser.PartialInterfaceMembers::Some(
        @parser.ExtendedAttributeList::None,
        @parser.PartialInterfaceMember::Const(_),
        @parser.PartialInterfaceMembers::None
      )
    ),
  )
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "PartialInterfaceMembers leaves an incomplete first member untouched" {
  let (parsed, rest) = parse_partial_interface_members("[Clamp] maplike<long>")
  assert_true(parsed is @parser.PartialInterfaceMembers::None)
  assert_true(rest is [(@lexer.TokenType::Punctuation, "["), ..])
}
