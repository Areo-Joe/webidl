///|
/// The type of the attribute, after resolving typedefs, must not be a nullable or
/// non-nullable version of any of the following types:
/// - a sequence type
/// - an async sequence type
/// - a dictionary type
/// - a record type
/// - a union type that has a nullable or non-nullable sequence type, dictionary,
///   or record as one of its flattened member types
fn check_attribute_type_no_dictionary(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
) -> Unit raise {
  let pending = [type_]
  let visited : Set[StringView] = Set([])
  while pending.pop() is Some(type_) {
    match type_ {
      UnionType(union_type, _) =>
        pending.push_iter(union_type.iter_member_types())
      SingleType(DistinguishableType(Identifier(identifier, _))) => {
        let name = strip_underscore(identifier)
        assert_false(dictionary_names.contains(name))
        if !visited.contains(name) && typedefs.get(name) is Some(typedef_) {
          visited.add(name)
          pending.push(typedef_.type_with_extended_attributes.type_)
        }
      }
      _ => ()
    }
  }
}
