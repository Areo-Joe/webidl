///|
/// The [PutForwards] extended attribute must take an identifier.
fn is_valid_put_forwards(attr : @parser.ExtendedAttribute) -> StringView? {
  match attr {
    Ident({ identifier: "PutForwards", value, }) => Some(value)
    _ => None
  }
}
