///|
/// Attributes whose type is a promise type must be read only.
/// Additionally, they cannot have any of the extended attributes
/// [LegacyLenientSetter], [PutForwards], [Replaceable], or [SameObject].
fn check_promise_attribute(
  attribute : Attribute,
  extended_attributes : @parser.ExtendedAttributeList,
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  let (type_, _, _) = resolve_type_with_extended_attributes(
    attribute.type_with_extended_attributes.type_,
    [],
    typedefs,
  )
  if type_ is SingleType(PromiseType(_)) {
    assert_true(
      attribute.tag
      is (PlainReadOnly
      | StaticReadOnly
      | StringifierReadOnly
      | NamespaceReadOnly),
    )
    assert_false(
      extended_attributes
      .iter()
      .any(attr => {
        is_valid_legacy_lenient_setter(attr) ||
        is_valid_put_forwards(attr) is Some(_) ||
        is_valid_replaceable(attr) ||
        is_valid_same_object(attr)
      }),
    )
  }
}
