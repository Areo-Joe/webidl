///|
fn[T : Eq] check_overload_extended_attribute(
  operations : Array[(Operation, @parser.ExtendedAttributeList)],
  constructors : Array[@parser.ExtendedAttributeList],
  attribute_value : (@parser.ExtendedAttributeList) -> T,
) -> Unit raise {
  let regular : Map[StringView, Array[@parser.ExtendedAttributeList]] = Map([])
  let static_operations : Map[StringView, Array[@parser.ExtendedAttributeList]] = Map([],
  )
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
  for (operation, attributes) in operations {
    add_operation(operation, attributes)
  }
  fn check_group(group : Array[@parser.ExtendedAttributeList]) raise {
    guard !group.is_empty() else { return }
    let value = attribute_value(group[0])
    assert_true(group.all(attributes => attribute_value(attributes) == value))
  }
  for group in regular.values() {
    check_group(group)
  }
  for group in static_operations.values() {
    check_group(group)
  }
  check_group(constructors)
}

///|
fn[T : Eq] check_overload_extended_attribute_on_interface(
  interface : Interface,
  attribute_value : (@parser.ExtendedAttributeList) -> T,
) -> Unit raise {
  let operations = []
  let constructors = []
  for member_ in interface.members {
    if member_.body is Constructor(_) {
      constructors.push(member_.extended_attribute_list)
    } else if Operation::from_interface_member(member_) is Some(operation) {
      operations.push((operation, member_.extended_attribute_list))
    }
  }
  for partial in interface.partials {
    for member_ in partial.members {
      if Operation::from_partial_interface_member(member_.body)
        is Some(operation) {
        operations.push((operation, member_.extended_attribute_list))
      }
    }
  }
  check_overload_extended_attribute(operations, constructors, attribute_value)
}

///|
fn[T : Eq] check_overload_extended_attribute_on_interface_mixin(
  mixin_ : InterfaceMixin,
  attribute_value : (@parser.ExtendedAttributeList) -> T,
) -> Unit raise {
  let operations = []
  for member_ in mixin_.members {
    if Operation::from_interface_mixin_member(member_.body) is Some(operation) {
      operations.push((operation, member_.extended_attribute_list))
    }
  }
  for partial in mixin_.partials {
    for member_ in partial.members {
      if Operation::from_interface_mixin_member(member_.body) is Some(operation) {
        operations.push((operation, member_.extended_attribute_list))
      }
    }
  }
  check_overload_extended_attribute(operations, [], attribute_value)
}
