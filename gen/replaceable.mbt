///|
/// The [Replaceable] extended attribute must take no arguments.
fn is_valid_replaceable(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "Replaceable"
    _ => false
  }
}
