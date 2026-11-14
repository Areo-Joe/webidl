///|
fn is_valid_legacy_no_interface_object(
  attr : @parser.ExtendedAttribute,
) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "LegacyNoInterfaceObject"
    _ => false
  }
}

///|
/// The [LegacyNoInterfaceObject] extended attribute must not be specified on an interface
/// that has any constructors or static operations defined on it.
fn check_legacy_no_interface_object_interface_no_constructor_or_static_operation(
  interface : Interface,
) -> Unit raise {
  assert_false(
    interface.members.iter().any(member_ => member_.body is Constructor(_)),
  )
  let operations = interface.members.filter_map(
    Operation::from_interface_member,
  )
  for partial in interface.partials {
    operations.push_iter(
      partial.members
      .iter()
      .filter_map(member_ => {
        Operation::from_partial_interface_member(member_.body)
      }),
    )
  }
  assert_false(operations.iter().any(operation => operation.tag is Static))
}

///|
fn check_interface_inheritance_no_legacy_no_interface_object(
  interface : Interface,
) -> Unit raise {
  guard interface.inheritance is Some(inheritance) else { return }
  assert_false(
    inheritance.extended_attribute_list
    .iter()
    .any(is_valid_legacy_no_interface_object),
  )
  check_interface_inheritance_no_legacy_no_interface_object(inheritance)
}
