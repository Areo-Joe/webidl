///|
/// If an identifier is used, it must reference a typedef whose type is a primitive type.
fn check_constant_type_identifier(
  identifier : StringView,
  typedefs : Array[TypeDef],
) -> Unit raise {
  assert_true(
    typedefs
    .iter()
    .any(typedef_ => {
      strip_underscore(typedef_.identifier) == strip_underscore(identifier) &&
      typedef_.type_with_extended_attributes.type_
      is SingleType(DistinguishableType(PrimitiveType(_, None)))
    }),
  )
}
