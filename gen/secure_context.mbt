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
/// If [SecureContext] appears on an overloaded operation, then it must appear on all overloads.
fn check_secure_context_overloads_on_interface(
  interface : Interface,
) -> Unit raise {
  let regular : Map[StringView, Array[@parser.ExtendedAttributeList]] = Map([])
  let static_operations : Map[StringView, Array[@parser.ExtendedAttributeList]] = Map([],
  )
  let constructors = []
  fn add_operation(
    operation : Operation,
    attributes : @parser.ExtendedAttributeList,
  ) raise {
    guard name_of_operation(operation) is Some(name) else { return }
    let groups = if operation.tag is Static {
      static_operations
    } else {
      regular
    }
    if groups.get(name) is Some(group) {
      group.push(attributes)
    } else {
      groups.set(name, [attributes])
    }
  }
  for member_ in interface.members {
    if member_.body is Constructor(_) {
      constructors.push(member_.extended_attribute_list)
    } else if Operation::from_interface_member(member_) is Some(operation) {
      add_operation(operation, member_.extended_attribute_list)
    }
  }
  for partial in interface.partials {
    for member_ in partial.members {
      if Operation::from_partial_interface_member(member_.body)
        is Some(operation) {
        add_operation(operation, member_.extended_attribute_list)
      }
    }
  }
  fn check_group(group : Array[@parser.ExtendedAttributeList]) raise {
    guard !group.is_empty() else { return }
    let marked = group[0].iter().any(is_valid_secure_context)
    assert_true(
      group.all(attributes => {
        attributes.iter().any(is_valid_secure_context) == marked
      }),
    )
  }
  for group in regular.values() {
    check_group(group)
  }
  for group in static_operations.values() {
    check_group(group)
  }
  check_group(constructors)
}
