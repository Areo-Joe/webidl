///|
/// The [LegacyLenientSetter] extended attribute must take no arguments.
fn is_valid_legacy_lenient_setter(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "LegacyLenientSetter"
    _ => false
  }
}

///|
/// It must not be used on anything other than a read only regular attribute.
/// An attribute with the [LegacyLenientSetter] extended attribute must not also be declared
/// with the [PutForwards] or [Replaceable] extended attributes.
/// The [LegacyLenientSetter] extended attribute must not be used on an attribute declared on a
/// namespace.
fn check_legacy_lenient_setter_on_attribute(
  attribute : Attribute,
  extended_attributes : @parser.ExtendedAttributeList,
) -> Unit raise {
  assert_true(
    attribute.tag is (PlainReadOnly | StringifierReadOnly | NamespaceReadOnly),
  )
  assert_false(attribute.tag is NamespaceReadOnly)
  assert_false(
    extended_attributes
    .iter()
    .any(attr => {
      is_valid_put_forwards(attr) is Some(_) || is_valid_replaceable(attr)
    }),
  )
}
