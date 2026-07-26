///|
fn iter_tokens(input : String) -> Tokens {
  (try! @lexer.tokenize(input)).view()
}

///|
test "recursive list iterators handle empty lists" {
  let tokens = iter_tokens("tail")
  let (callback_members, _) = CallbackInterfaceMembers::parse(tokens)
  assert_eq(callback_members.iter().count(), 0)
  let (arguments, _) = Arguments::parse(tokens)
  assert_eq(arguments.iter().count(), 0)
  let (union_member_types, _) = UnionMemberTypes::parse(tokens)
  assert_eq(union_member_types.iter().count(), 0)
  let (extended_attributes, _) = ExtendedAttributes::parse(tokens)
  assert_eq(extended_attributes.iter().count(), 0)
  let (identifiers, _) = Identifiers::parse(tokens)
  assert_eq(identifiers.iter().count(), 0)
  let (integers, _) = Integers::parse(tokens)
  assert_eq(integers.iter().count(), 0)
  let (namespace_members, _) = NamespaceMembers::parse(tokens)
  assert_eq(namespace_members.iter().count(), 0)
  let (interface_members, _) = InterfaceMembers::parse(tokens)
  assert_eq(interface_members.iter().count(), 0)
  let (definitions, _) = Definitions::parse(tokens)
  assert_eq(definitions.iter().count(), 0)
}

///|
test "recursive list iterators visit every parsed element" {
  let (callback_members, _) = CallbackInterfaceMembers::parse(
    iter_tokens("const long value = 1; long invoke(); tail"),
  )
  assert_eq(callback_members.iter().count(), 2)

  let (arguments, _) = Arguments::parse(
    iter_tokens(", DOMString value, optional long count tail"),
  )
  assert_eq(arguments.iter().count(), 2)

  let (union_member_types, _) = UnionMemberTypes::parse(
    iter_tokens("or long or DOMString tail"),
  )
  assert_eq(union_member_types.iter().count(), 2)

  let (extended_attributes, _) = ExtendedAttributes::parse(
    iter_tokens(", Clamp, Exposed tail"),
  )
  assert_eq(extended_attributes.iter().count(), 2)

  let (identifiers, _) = Identifiers::parse(iter_tokens(", One, Two tail"))
  assert_eq(identifiers.iter().to_array(), ["One", "Two"])

  let (integers, _) = Integers::parse(iter_tokens(", 1, -2 tail"))
  assert_eq(integers.iter().to_array(), ["1", "-2"])

  let (namespace_members, _) = NamespaceMembers::parse(
    iter_tokens("const long value = 1; long operation(); tail"),
  )
  assert_eq(namespace_members.iter().count(), 2)

  let (interface_members, _) = InterfaceMembers::parse(
    iter_tokens("const long value = 1; constructor(); tail"),
  )
  assert_eq(interface_members.iter().count(), 2)

  let (definitions, _) = Definitions::parse(
    iter_tokens("interface Example {}; dictionary Options {}; tail"),
  )
  assert_eq(definitions.iter().count(), 2)
}

///|
test "complete list iterators include their first and remaining elements" {
  let (argument_list, _) = ArgumentList::parse(
    iter_tokens("DOMString value, optional long count"),
  )
  assert_eq(argument_list.iter().count(), 2)

  let (attribute_list, _) = ExtendedAttributeList::parse(
    iter_tokens("[Clamp, Exposed] tail"),
  )
  assert_eq(attribute_list.iter().count(), 2)

  guard IdentifierList::parse(iter_tokens("One, Two, Three tail"))
    is Some((identifier_list, _)) else {
    fail("expected identifier list")
  }
  assert_eq(identifier_list.iter().to_array(), ["One", "Two", "Three"])

  guard IntegerList::parse(iter_tokens("1, -2, 3 tail"))
    is Some((integer_list, _)) else {
    fail("expected integer list")
  }
  assert_eq(integer_list.iter().to_array(), ["1", "-2", "3"])

  guard UnionType::parse(iter_tokens("(long or DOMString or boolean) tail"))
    is Some((union_type, _)) else {
    fail("expected union type")
  }
  assert_eq(union_type.iter().count(), 3)

  guard EnumValueList::parse(iter_tokens("\"one\", \"two\", \"three\" tail"))
    is Some((enum_value_list, _)) else {
    fail("expected enum value list")
  }
  assert_eq(enum_value_list.iter().to_array(), [
    "\"one\"", "\"two\"", "\"three\"",
  ])
}

///|
test "optional complete list iterators handle empty lists" {
  let tokens = iter_tokens("tail")
  let (argument_list, _) = ArgumentList::parse(tokens)
  assert_eq(argument_list.iter().count(), 0)
  let (attribute_list, _) = ExtendedAttributeList::parse(tokens)
  assert_eq(attribute_list.iter().count(), 0)
}
