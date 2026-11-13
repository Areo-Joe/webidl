///|
fn parse_partial_interface_member(
  input : String,
) -> (@parser.PartialInterfaceMember, @parser.Tokens)? {
  @parser.PartialInterfaceMember::parse((try! @lexer.tokenize(input)).view())
}

///|
test "PartialInterfaceMember parses every alternative" {
  assert_true(
    parse_partial_interface_member("const long value = 1; tail")
    is Some((@parser.PartialInterfaceMember::Const(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("long operation(); tail")
    is Some((@parser.PartialInterfaceMember::Operation(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("stringifier; tail")
    is Some((@parser.PartialInterfaceMember::Stringifier(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("static attribute DOMString name; tail")
    is Some((@parser.PartialInterfaceMember::StaticMember(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("iterable<long>; tail")
    is Some((@parser.PartialInterfaceMember::Iterable(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("async_iterable<long>; tail")
    is Some((@parser.PartialInterfaceMember::AsyncIterable(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("readonly attribute DOMString name; tail")
    is Some((@parser.PartialInterfaceMember::ReadOnlyMember(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("attribute DOMString name; tail")
    is Some(
      (@parser.PartialInterfaceMember::ReadWriteAttribute(_), [(_, "tail")])
    ),
  )
  assert_true(
    parse_partial_interface_member("maplike<DOMString, long>; tail")
    is Some(
      (@parser.PartialInterfaceMember::ReadWriteMaplike(_), [(_, "tail")])
    ),
  )
  assert_true(
    parse_partial_interface_member("setlike<long>; tail")
    is Some(
      (@parser.PartialInterfaceMember::ReadWriteSetlike(_), [(_, "tail")])
    ),
  )
  assert_true(
    parse_partial_interface_member("inherit attribute DOMString name; tail")
    is Some(
      (@parser.PartialInterfaceMember::InheritAttribute(_), [(_, "tail")])
    ),
  )
}

///|
test "PartialInterfaceMember rejects unsupported and incomplete members" {
  assert_true(parse_partial_interface_member("constructor();") is None)
  assert_true(
    parse_partial_interface_member("readonly iterable<long>;") is None,
  )
  assert_true(parse_partial_interface_member("maplike<DOMString>;") is None)
}
