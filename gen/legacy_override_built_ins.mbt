///|
/// The [LegacyOverrideBuiltIns] extended attribute must take no arguments
fn is_valid_legacy_override_built_ins(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "LegacyOverrideBuiltIns"
    _ => false
  }
}
