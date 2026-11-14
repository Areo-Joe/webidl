///|
/// The [LegacyLenientSetter] extended attribute must take no arguments.
fn is_valid_legacy_lenient_setter(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "LegacyLenientSetter"
    _ => false
  }
}
