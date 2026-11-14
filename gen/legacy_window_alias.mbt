///|
priv enum LegacyWindowAlias {
  Ident(StringView)
  IdentList(Array[StringView])
}

///|
fn is_valid_legacy_window_alias(
  attr : @parser.ExtendedAttribute,
) -> LegacyWindowAlias? {
  match attr {
    Ident({ identifier: "LegacyWindowAlias", value, }) => Some(Ident(value))
    IdentList({ identifier: "LegacyWindowAlias", identifier_list, }) =>
      Some(IdentList(identifier_list.iter().collect()))
    _ => None
  }
}

///|
fn legacy_window_alias_names(
  attr_list : @parser.ExtendedAttributeList,
) -> Array[StringView] {
  attr_list
  .iter()
  .filter_map(is_valid_legacy_window_alias)
  .map(window_alias => {
    match window_alias {
      Ident(value) => [strip_underscore(value)]
      IdentList(values) => values.map(strip_underscore)
    }
  })
  .collect()
  .flatten()
}

///|
fn check_legacy_window_alias_names(interfaces : Array[Interface]) -> Unit raise {
  let interface_names = interface_object_names(interfaces)
  let factory_names = Set(
    interfaces
    .map(interface => {
      interface.extended_attribute_list
      .iter()
      .filter_map(is_valid_legacy_factory_function)
      .map(factory => strip_underscore(factory.value))
      .collect()
    })
    .flatten(),
  )
  let seen = Set([])
  for interface in interfaces {
    for name in legacy_window_alias_names(interface.extended_attribute_list) {
      assert_true(
        name != "constructor" && name != "toString" && !name.has_prefix("_"),
      )
      assert_false(seen.contains(name))
      assert_false(interface_names.contains(name))
      assert_false(factory_names.contains(name))
      seen.add(name)
    }
  }
}

///|
/// An interface must not have more than one [LegacyWindowAlias] extended attributes specified.
fn check_legacy_window_alias_on_interface(
  interface : Interface,
  attribute_count : Int32,
  interface_exposure_set : ExposureSet,
) -> Unit raise {
  assert_eq(attribute_count, 1)
  assert_false(
    interface.extended_attribute_list
    .iter()
    .any(is_valid_legacy_no_interface_object),
  )
  assert_false(
    interface.extended_attribute_list
    .iter()
    .any(attr => is_valid_legacy_namespace(attr) is Some(_)),
  )
  assert_true(
    match interface_exposure_set {
      All => true
      List(names) => names.contains("Window")
    },
  )
}
