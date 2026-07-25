///|
fn parse_partial_interface_member(
  input : String,
) -> (PartialInterfaceMember, Tokens)? {
  PartialInterfaceMember::parse((try! @lexer.tokenize(input)).view())
}

///|
test "PartialInterfaceMember parses every alternative" {
  assert_true(
    parse_partial_interface_member("const long value = 1; tail")
    is Some((PartialInterfaceMember::Const(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("long operation(); tail")
    is Some((PartialInterfaceMember::Operation(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("stringifier; tail")
    is Some((PartialInterfaceMember::Stringifier(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("static attribute DOMString name; tail")
    is Some((PartialInterfaceMember::StaticMember(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("iterable<long>; tail")
    is Some((PartialInterfaceMember::Iterable(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("async_iterable<long>; tail")
    is Some((PartialInterfaceMember::AsyncIterable(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("readonly attribute DOMString name; tail")
    is Some((PartialInterfaceMember::ReadOnlyMember(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("attribute DOMString name; tail")
    is Some((PartialInterfaceMember::ReadWriteAttribute(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("maplike<DOMString, long>; tail")
    is Some((PartialInterfaceMember::ReadWriteMaplike(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("setlike<long>; tail")
    is Some((PartialInterfaceMember::ReadWriteSetlike(_), [(_, "tail")])),
  )
  assert_true(
    parse_partial_interface_member("inherit attribute DOMString name; tail")
    is Some((PartialInterfaceMember::InheritAttribute(_), [(_, "tail")])),
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
