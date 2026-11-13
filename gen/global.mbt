///|
priv enum Global {
  Ident(StringView)
  IdentList(Array[StringView])
}

///|
/// The [Global] extended attribute also defines the global names for the interface:
///
/// If the [Global] extended attribute takes an identifier
/// « the given identifier »
///
/// If the [Global] extended attribute takes an identifier list
/// the identifier list
///
/// The [Global] extended attribute must be one of the forms given above.
fn is_valid_global(attr : @parser.ExtendedAttribute) -> Global? {
  match attr {
    Ident({ identifier: "Global", value, }) => Some(Ident(value))
    IdentList({ identifier: "Global", identifier_list, }) =>
      Some(IdentList(identifier_list.iter().collect()))
    _ => None
  }
}

///|
fn global_names(attr_list : @parser.ExtendedAttributeList) -> Array[StringView] {
  attr_list
  .iter()
  .filter_map(is_valid_global)
  .map(x => {
    match x {
      Ident(value) => [strip_underscore(value)]
      IdentList(identifier_list) => identifier_list.map(strip_underscore)
    }
  })
  .collect()
  .flatten()
}

///|
/// If the [Global] extended attributes is used on an interface, then:
/// The interface must not define a constructor operation.
fn check_global_interface_no_constructor(interface : Interface) -> Unit raise {
  if interface.extended_attribute_list
    .iter()
    .any(attr => is_valid_global(attr) is Some(_)) {
    assert_false(
      interface.members
      .iter()
      .any(interface_member => {
        interface_member.body is @parser.InterfaceMember::Constructor(_)
      }),
    )
  }
}

///|
/// If the [Global] extended attributes is used on an interface, then:
/// The interface must not also be declared with the [LegacyOverrideBuiltIns] extended attribute.
fn check_global_interface_no_legacy_override_built_ins(
  interface : Interface,
) -> Unit raise {
  if interface.extended_attribute_list
    .iter()
    .any(attr => is_valid_global(attr) is Some(_)) {
    assert_false(
      interface.extended_attribute_list
      .iter()
      .any(is_valid_legacy_override_built_ins),
    )
  }
}
