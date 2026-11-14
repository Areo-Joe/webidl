///|
/// The [LegacyNamespace] extended attribute must take an identifier.
fn is_valid_legacy_namespace(attr : @parser.ExtendedAttribute) -> StringView? {
  match attr {
    Ident({ identifier: "LegacyNamespace", value, }) => Some(value)
    _ => None
  }
}
