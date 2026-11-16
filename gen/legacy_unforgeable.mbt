///|
/// The [LegacyUnforgeable] extended attribute must take no arguments.
fn is_valid_legacy_unforgeable(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "LegacyUnforgeable"
    _ => false
  }
}

///|
fn has_legacy_unforgeable(
  extended_attributes : @parser.ExtendedAttributeList,
) -> Bool {
  extended_attributes.iter().any(is_valid_legacy_unforgeable)
}

///|
/// The [LegacyUnforgeable] extended attribute must not appear
/// on anything other than a regular attribute or a non-static operation.
/// The [LegacyUnforgeable] extended attribute must not be used
/// on an attribute declared on a namespace.
fn check_legacy_unforgeable_on_attribute(attribute : Attribute) -> Unit raise {
  assert_true(
    attribute.tag
    is (Inherit
    | StringifierReadOnly
    | StringifierReadWrite
    | PlainReadOnly
    | PlainReadWrite
    | NamespaceReadOnly),
  )
  assert_false(attribute.tag is NamespaceReadOnly)
}

///|
fn check_legacy_unforgeable_on_operation(operation : Operation) -> Unit raise {
  assert_false(operation.tag is Static)
}

///|
/// If it does appear on an operation, then it must appear on all operations
/// with the same identifier on that interface.
fn check_legacy_unforgeable_operations(interface : Interface) -> Unit raise {
  let operations = interface.operations_with_extended_attributes()
  let names = []
  let seen : Set[StringView] = Set([])
  for (operation, _) in operations {
    if name_of_operation(operation) is Some(name) && !seen.contains(name) {
      seen.add(name)
      names.push(name)
    }
  }
  for name in names {
    let marked = []
    for (operation, extended_attributes) in operations {
      if name_of_operation(operation) == Some(name) {
        marked.push(has_legacy_unforgeable(extended_attributes))
      }
    }
    if marked.any(value => value) {
      assert_true(marked.all(value => value))
    }
  }
}

///|
fn regular_member_names(interface : Interface) -> Array[StringView] raise {
  let names = []
  let seen : Set[StringView] = Set([])
  for (attribute, _) in interface.attributes_with_extended_attributes() {
    if attribute.tag is (StaticReadOnly | StaticReadWrite) {
      continue
    }
    let name = name_of_attribute(attribute)
    if !seen.contains(name) {
      seen.add(name)
      names.push(name)
    }
  }
  for (operation, _) in interface.operations_with_extended_attributes() {
    if operation.tag is Static {
      continue
    }
    if name_of_operation(operation) is Some(name) && !seen.contains(name) {
      seen.add(name)
      names.push(name)
    }
  }
  names
}

///|
fn unforgeable_member_names(interface : Interface) -> Array[StringView] raise {
  let names = []
  let seen : Set[StringView] = Set([])
  for
    (attribute, extended_attributes) in interface.attributes_with_extended_attributes() {
    if attribute.tag is (StaticReadOnly | StaticReadWrite) {
      continue
    }
    if has_legacy_unforgeable(extended_attributes) {
      let name = name_of_attribute(attribute)
      if !seen.contains(name) {
        seen.add(name)
        names.push(name)
      }
    }
  }
  for
    (operation, extended_attributes) in interface.operations_with_extended_attributes() {
    if operation.tag is Static {
      continue
    }
    if has_legacy_unforgeable(extended_attributes) &&
      name_of_operation(operation) is Some(name) &&
      !seen.contains(name) {
      seen.add(name)
      names.push(name)
    }
  }
  names
}

///|
/// If an attribute or operation X is unforgeable on an interface A,
/// and A is one of the inherited interfaces of another interface B,
/// then B must not have a regular attribute or non-static operation
/// with the same identifier as X.
fn check_legacy_unforgeable_inheritance(interface : Interface) -> Unit raise {
  let members = regular_member_names(interface)
  let mut ancestor = interface.inheritance
  while ancestor is Some(current) {
    for name in unforgeable_member_names(current) {
      assert_false(members.contains(name))
    }
    ancestor = current.inheritance
  }
}

///|
fn check_legacy_unforgeable_on_interface(interface : Interface) -> Unit raise {
  for
    (operation, extended_attributes) in interface.operations_with_extended_attributes() {
    if has_legacy_unforgeable(extended_attributes) {
      check_legacy_unforgeable_on_operation(operation)
    }
  }
  check_legacy_unforgeable_operations(interface)
  check_legacy_unforgeable_inheritance(interface)
}
