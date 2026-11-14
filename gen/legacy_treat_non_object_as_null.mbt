///|
fn is_valid_legacy_treat_non_object_as_null(
  attr : @parser.ExtendedAttribute,
) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "LegacyTreatNonObjectAsNull"
    _ => false
  }
}
