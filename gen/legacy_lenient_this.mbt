///|
/// The [LegacyLenientThis] extended attribute must take no arguments.
fn is_valid_legacy_lenient_this(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "LegacyLenientThis"
    _ => false
  }
}

///|
/// It must not be used on a static attribute.
/// The [LegacyLenientThis] extended attribute must not be used on an attribute declared on a
/// namespace.
fn check_legacy_lenient_this_on_attribute(attribute : Attribute) -> Unit raise {
  assert_false(attribute.tag is (StaticReadOnly | StaticReadWrite))
  assert_false(attribute.tag is NamespaceReadOnly)
}
