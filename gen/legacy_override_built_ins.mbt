///|
/// The [LegacyOverrideBuiltIns] extended attribute must take no arguments
fn is_valid_legacy_override_built_ins(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "LegacyOverrideBuiltIns"
    _ => false
  }
}

///|
/// If the [LegacyOverrideBuiltIns] extended attribute is specified on a partial interface definition,
/// it is considered to appear on the interface itself.
fn Interface::has_legacy_override_built_ins(self : Self) -> Bool {
  self.extended_attribute_list.iter().any(is_valid_legacy_override_built_ins) ||
  self.partials.any(partial => {
    partial.extended_attribute_list
    .iter()
    .any(is_valid_legacy_override_built_ins)
  })
}

///|
fn check_legacy_override_built_ins_interface_has_named_getter(
  interface : Interface,
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  let operations = interface.members.filter_map(
    Operation::from_interface_member,
  )
  for partial in interface.partials {
    operations.push_iter(
      partial.members
      .iter()
      .filter_map(member_ => {
        Operation::from_partial_interface_member(member_.body)
      }),
    )
  }
  assert_true(operations.any(operation => operation.is_named_getter(typedefs)))
}

///|
fn check_legacy_override_built_ins_partial_interface_has_named_getter(
  partial : PartialInterface,
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  assert_true(
    partial.members
    .iter()
    .filter_map(member_ => {
      Operation::from_partial_interface_member(member_.body)
    })
    .any(operation => operation.is_named_getter(typedefs)),
  )
}
