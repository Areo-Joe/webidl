///|
fn parse_partial_interface_members(
  input : String,
) -> (PartialInterfaceMembers, Tokens) {
  PartialInterfaceMembers::parse((try! @lexer.tokenize(input)).view())
}

///|
test "PartialInterfaceMembers parses epsilon without consuming input" {
  let (parsed, rest) = parse_partial_interface_members("tail")
  assert_true(parsed is PartialInterfaceMembers::None)
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "PartialInterfaceMembers parses attributed and plain members recursively" {
  let (parsed, rest) = parse_partial_interface_members(
    "[Clamp] attribute DOMString name; const long value = 1; tail",
  )
  assert_true(
    parsed
    is PartialInterfaceMembers::Some(
      ExtendedAttributeList::Some(_, _),
      PartialInterfaceMember::ReadWriteAttribute(_),
      PartialInterfaceMembers::Some(
        ExtendedAttributeList::None,
        PartialInterfaceMember::Const(_),
        PartialInterfaceMembers::None
      )
    ),
  )
  assert_true(rest is [(@lexer.TokenType::Identifier, "tail")])
}

///|
test "PartialInterfaceMembers leaves an incomplete first member untouched" {
  let (parsed, rest) = parse_partial_interface_members("[Clamp] maplike<long>")
  assert_true(parsed is PartialInterfaceMembers::None)
  assert_true(rest is [(@lexer.TokenType::Punctuation, "["), ..])
}
