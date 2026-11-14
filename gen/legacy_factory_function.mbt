///|
/// The [LegacyFactoryFunction] extended attribute must take a named argument list.
fn is_valid_legacy_factory_function(
  attr : @parser.ExtendedAttribute,
) -> @parser.ExtendedAttributeNamedArgList? {
  match attr {
    NamedArgList(factory) if factory.identifier == "LegacyFactoryFunction" =>
      Some(factory)
    _ => None
  }
}

///|
/// The [LegacyFactoryFunction] and [Global] extended attributes must not be specified on the same interface.
fn check_legacy_factory_function_interface_no_global(
  interface : Interface,
) -> Unit raise {
  assert_false(
    interface.extended_attribute_list
    .iter()
    .any(attr => is_valid_global(attr) is Some(_)),
  )
}

///|
fn check_legacy_factory_function_names(
  interfaces : Array[Interface],
) -> Unit raise {
  let interface_object_names = Set(
    interfaces
    .filter(interface => {
      !interface.extended_attribute_list
      .iter()
      .any(is_valid_legacy_no_interface_object)
    })
    .map(name_of_interface),
  )
  let alias_names = Set(
    interfaces
    .map(interface => {
      legacy_window_alias_names(interface.extended_attribute_list)
    })
    .flatten(),
  )
  let owners : Map[StringView, StringView] = Map([])
  for interface in interfaces {
    let owner = name_of_interface(interface)
    for attr in interface.extended_attribute_list.iter() {
      if is_valid_legacy_factory_function(attr) is Some(factory) {
        let name = strip_underscore(factory.value)
        assert_true(
          name != "constructor" && name != "toString" && !name.has_prefix("_"),
        )
        assert_false(interface_object_names.contains(name))
        assert_false(alias_names.contains(name))
        if owners.get(name) is Some(previous) {
          assert_eq(previous, owner)
        } else {
          owners.set(name, owner)
        }
      }
    }
  }
}

///|
fn check_legacy_factory_function_overloads(
  interface : Interface,
  typedefs : Map[StringView, TypeDef],
  definitions : Map[StringView, Definition],
) -> Unit raise {
  let groups : Map[
    StringView,
    Array[(@parser.ExtendedAttribute, @parser.ArgumentList)],
  ] = Map([])
  for attr in interface.extended_attribute_list.iter() {
    if is_valid_legacy_factory_function(attr) is Some(factory) {
      let name = strip_underscore(factory.value)
      if groups.get(name) is Some(group) {
        group.push((attr, factory.argument_list))
      } else {
        groups.set(name, [(attr, factory.argument_list)])
      }
    }
  }
  for group in groups.values() {
    check_effective_overload_set(
      compute_effective_overload_set(group, 0),
      typedefs,
      definitions,
    )
  }
}
