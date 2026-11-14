///|
/// Frozen array types must only be used as the type of regular attributes or static attributes defined on an interface.
fn check_frozen_array_type(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
  allow_frozen_array~ : Bool,
) -> Unit raise {
  let pending = [(type_.iter_types(), allow_frozen_array)]
  let visited : Set[(StringView, Bool)] = Set([])
  while pending.pop() is Some((types, allow_frozen_array)) {
    guard types.next() is Some(type_) else { continue }
    pending.push((types, false))
    match type_ {
      SingleType(DistinguishableType(FrozenArray(_, _))) =>
        assert_true(allow_frozen_array)
      SingleType(DistinguishableType(Identifier(identifier, _))) => {
        let name = strip_underscore(identifier)
        let state = (name, allow_frozen_array)
        if !visited.contains(state) && typedefs.get(name) is Some(typedef_) {
          visited.add(state)
          pending.push(
            (
              typedef_.type_with_extended_attributes.type_.iter_types(),
              allow_frozen_array,
            ),
          )
        }
      }
      _ => ()
    }
  }
}
