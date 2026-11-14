///|
fn check_overload_extended_attribute_on_interface(
  interface : Interface,
  is_marked : (@parser.ExtendedAttribute) -> Bool,
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
    let marked = group[0].iter().any(is_marked)
    assert_true(
      group.all(attributes => attributes.iter().any(is_marked) == marked),
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
