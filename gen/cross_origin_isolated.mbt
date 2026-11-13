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
  interface_marked~ : Bool,
) -> Unit raise {
  if interface_marked {
    for interface_member in interface.members {
      assert_false(
        interface_member.extended_attribute_list
        .iter()
        .any(is_valid_cross_origin_isolated),
      )
    }
  }

  for partial in interface.partials {
    if interface_marked ||
      partial.extended_attribute_list.iter().any(is_valid_cross_origin_isolated) {
      for partial_interface_member in partial.members {
        assert_false(
          partial_interface_member.extended_attribute_list
          .iter()
          .any(is_valid_cross_origin_isolated),
        )
      }
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
