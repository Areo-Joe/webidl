///|
/// Async sequences must not be used as the type of an attribute or constant.
fn check_attribute_type_no_async_sequence(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  let pending = [type_]
  let visited : Set[StringView] = Set([])
  while pending.pop() is Some(type_) {
    assert_false(type_ is SingleType(DistinguishableType(AsyncSequence(_, _))))
    match type_ {
      SingleType(DistinguishableType(Identifier(identifier, _))) => {
        let name = strip_underscore(identifier)
        if !visited.contains(name) && typedefs.get(name) is Some(typedef_) {
          visited.add(name)
          pending.push(typedef_.type_with_extended_attributes.type_)
        }
      }
      _ => ()
    }
  }
}
