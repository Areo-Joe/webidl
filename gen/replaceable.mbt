///|
/// The [Replaceable] extended attribute must take no arguments.
fn is_valid_replaceable(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "Replaceable"
    _ => false
  }
}

///|
/// An attribute with the [Replaceable] extended attribute must not also be declared
/// with the [LegacyLenientSetter] or [PutForwards] extended attributes.
/// The [Replaceable] extended attribute must not be used on an attribute that is not read only.
/// The [Replaceable] extended attribute must not be used on a static attribute.
/// The [Replaceable] extended attribute must not be used on an attribute declared on a namespace.
fn check_replaceable_on_attribute(
  attribute : Attribute,
  extended_attributes : @parser.ExtendedAttributeList,
) -> Unit raise {
  assert_true(
    attribute.tag
    is (PlainReadOnly
    | StaticReadOnly
    | StringifierReadOnly
    | NamespaceReadOnly),
  )
  assert_false(attribute.tag is (StaticReadOnly | StaticReadWrite))
  assert_false(attribute.tag is NamespaceReadOnly)
  assert_false(
    extended_attributes
    .iter()
    .any(attr => {
      is_valid_legacy_lenient_setter(attr) ||
      is_valid_put_forwards(attr) is Some(_)
    }),
  )
}
