///|
/// The [SameObject] extended attribute must take no arguments.
fn is_valid_same_object(attr : @parser.ExtendedAttribute) -> Bool {
  match attr {
    NoArgs(attr) => attr.identifier == "SameObject"
    _ => false
  }
}

///|
/// The [SameObject] extended attribute must not be used on anything other than
/// a read only attribute whose type is an interface type or object.
fn check_same_object_on_attribute(
  attribute : Attribute,
  typedefs : Map[StringView, TypeDef],
  definitions : Map[StringView, Definition],
) -> Unit raise {
  assert_true(
    attribute.tag
    is (PlainReadOnly
    | StaticReadOnly
    | StringifierReadOnly
    | NamespaceReadOnly),
  )
  let (type_, nullable, _) = resolve_type_with_extended_attributes(
    attribute.type_with_extended_attributes.type_,
    [],
    typedefs,
  )
  assert_false(nullable)
  assert_true(
    match type_ {
      SingleType(DistinguishableType(Object(_))) => true
      SingleType(DistinguishableType(Identifier(identifier, _))) =>
        definitions.get(strip_underscore(identifier)) is Some(Interface(_))
      _ => false
    },
  )
}
