///|
/// The [SameObject] extended attribute must take no arguments.
fn is_valid_same_object(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "SameObject"
    _ => false
  }
}
