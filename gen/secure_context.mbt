///|
/// The [SecureContext] extended attribute must take no arguments.
fn is_valid_secure_context(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "SecureContext"
    _ => false
  }
}

///|
fn check_is_valid_secure_context_on_interface(
  interface : Interface,
  interface_marked~ : Bool,
) -> Unit raise {
  if interface_marked {
    for member_ in interface.members {
      assert_false(
        member_.extended_attribute_list.iter().any(is_valid_secure_context),
      )
    }
  }
  for partial in interface.partials {
    if interface_marked ||
      partial.extended_attribute_list.iter().any(is_valid_secure_context) {
      for member_ in partial.members {
        assert_false(
          member_.extended_attribute_list.iter().any(is_valid_secure_context),
        )
      }
    }
  }
}

///|
/// The [SecureContext] extended attribute must not be specified both on
/// an interface mixin member and its interface mixin or partial interface mixin;
fn check_is_valid_secure_context_on_interface_mixin(
  mixin_ : InterfaceMixin,
  mixin_marked~ : Bool,
) -> Unit raise {
  if mixin_marked {
    for member_ in mixin_.members {
      assert_false(
        member_.extended_attribute_list.iter().any(is_valid_secure_context),
      )
    }
  }
  for partial in mixin_.partials {
    if mixin_marked ||
      partial.extended_attribute_list.iter().any(is_valid_secure_context) {
      for member_ in partial.members {
        assert_false(
          member_.extended_attribute_list.iter().any(is_valid_secure_context),
        )
      }
    }
  }
}

///|
fn check_interface_inheritance_no_secure_context(
  interface : Interface,
) -> Unit raise {
  guard interface.inheritance is Some(inheritance) else { return }
  assert_false(
    inheritance.extended_attribute_list.iter().any(is_valid_secure_context),
  )
  check_interface_inheritance_no_secure_context(inheritance)
}

///|
fn check_secure_context_interface_no_cross_origin_isolated(
  interface : Interface,
  interface_marked~ : Bool,
  interface_cross_origin_isolated~ : Bool,
) -> Unit raise {
  if interface_marked {
    assert_false(interface_cross_origin_isolated)
  }
  fn check_member(
    attributes : @parser.ExtendedAttributeList,
    cross_origin_isolated : Bool,
  ) raise {
    if attributes.iter().any(is_valid_secure_context) {
      assert_false(
        cross_origin_isolated ||
        attributes.iter().any(is_valid_cross_origin_isolated),
      )
    }
  }
  for member_ in interface.members {
    check_member(
      member_.extended_attribute_list,
      interface_cross_origin_isolated,
    )
  }
  for partial in interface.partials {
    let cross_origin_isolated = interface_cross_origin_isolated ||
      partial.extended_attribute_list.iter().any(is_valid_cross_origin_isolated)
    for member_ in partial.members {
      check_member(member_.extended_attribute_list, cross_origin_isolated)
    }
  }
}

///|
/// [SecureContext] must not be specified on a construct is that is conditionally exposed on [CrossOriginIsolated].
fn check_secure_context_interface_mixin_no_cross_origin_isolated(
  mixin_ : InterfaceMixin,
  mixin_cross_origin_isolated~ : Bool,
  host_cross_origin_isolated~ : Bool,
) -> Unit raise {
  fn check_member(
    attributes : @parser.ExtendedAttributeList,
    cross_origin_isolated : Bool,
  ) raise {
    if attributes.iter().any(is_valid_secure_context) {
      assert_false(
        cross_origin_isolated ||
        attributes.iter().any(is_valid_cross_origin_isolated),
      )
    }
  }
  let cross_origin_isolated = mixin_cross_origin_isolated ||
    host_cross_origin_isolated
  for member_ in mixin_.members {
    check_member(member_.extended_attribute_list, cross_origin_isolated)
  }
  for partial in mixin_.partials {
    let cross_origin_isolated = cross_origin_isolated ||
      partial.extended_attribute_list.iter().any(is_valid_cross_origin_isolated)
    for member_ in partial.members {
      check_member(member_.extended_attribute_list, cross_origin_isolated)
    }
  }
}

///|
/// If [SecureContext] appears on an overloaded operation, then it must appear on all overloads.
fn check_secure_context_overloads_on_interface(
  interface : Interface,
) -> Unit raise {
  check_overload_extended_attribute_on_interface(interface, attributes => {
    attributes.iter().any(is_valid_secure_context)
  })
}

///|
/// If [SecureContext] appears on an overloaded operation, then it must appear on all overloads.
fn check_secure_context_overloads_on_interface_mixin(
  mixin_ : InterfaceMixin,
) -> Unit raise {
  check_overload_extended_attribute_on_interface_mixin(mixin_, attributes => {
    attributes.iter().any(is_valid_secure_context)
  })
}
