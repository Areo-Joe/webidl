///|
/// The Type must not be the identifier of the same or another typedef.
fn check_typedef_type_not_typedef(typedefs : Array[TypeDef]) -> Unit raise {
  let typedef_names = Set(typedefs.map(x => strip_underscore(x.identifier)))
  for typedef_ in typedefs {
    if typedef_.type_with_extended_attributes.type_
      is SingleType(DistinguishableType(Identifier(identifier, None))) {
      assert_false(typedef_names.contains(strip_underscore(identifier)))
    }
  }
}
