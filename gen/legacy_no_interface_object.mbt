///|
fn is_valid_legacy_no_interface_object(
  attr : @parser.ExtendedAttribute,
) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "LegacyNoInterfaceObject"
    _ => false
  }
}
