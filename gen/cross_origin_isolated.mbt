///|
fn is_valid_cross_origin_isolated(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "CrossOriginIsolated"
    _ => false
  }
}

///|
/// The [CrossOriginIsolated] extended attribute must not be specified both on
/// an interface member and its interface or partial interface;
fn check_is_valid_cross_origin_isolated_on_interface(
  interface : Interface,
) -> Unit raise {
  for x in interface.members.iter() {
    let attrs = x.extended_attribute_list
    for attr in attrs.iter() {
      assert_false(is_valid_cross_origin_isolated(attr))
    }
  }
}

///|
/// An interface without the [CrossOriginIsolated] extended attribute must not inherit from another interface that does specify [CrossOriginIsolated].
fn check_interface_inheritance_no_cross_origin_isolated(
  interfaces : Array[Interface],
  interface : Interface,
) -> Unit raise {
  guard interface.inheritance is Some(inheritance) else { return }

  assert_false(
    inheritance.extended_attribute_list
    .iter()
    .any(is_valid_cross_origin_isolated),
  )

  check_interface_inheritance_no_cross_origin_isolated(interfaces, inheritance)
}
