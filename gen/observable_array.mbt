///|
/// Observable array types must only be used as the type of regular attributes defined on an interface.
fn check_observable_array_type(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
  allow_observable_array~ : Bool,
) -> Unit raise {
  let pending = [(type_.iter_types(), allow_observable_array)]
  let visited : Set[(StringView, Bool)] = Set([])
  while pending.pop() is Some((types, allow_observable_array)) {
    guard types.next() is Some(type_) else { continue }
    pending.push((types, false))
    match type_ {
      SingleType(DistinguishableType(ObservableArray(inner, _))) => {
        assert_true(allow_observable_array)
        check_observable_array_element_type(
          inner.type_,
          typedefs,
          dictionary_names,
        )
      }
      SingleType(DistinguishableType(Identifier(identifier, _))) => {
        let name = strip_underscore(identifier)
        let state = (name, allow_observable_array)
        if !visited.contains(state) && typedefs.get(name) is Some(typedef_) {
          visited.add(state)
          pending.push(
            (
              typedef_.type_with_extended_attributes.type_.iter_types(),
              allow_observable_array,
            ),
          )
        }
      }
      _ => ()
    }
  }
}

///|
/// The parameterized type T must not be a dictionary type, sequence type, record type, or observable array type. However, T may be nullable.
fn check_observable_array_element_type(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
) -> Unit raise {
  let mut current = type_
  let visited : Set[StringView] = Set([])
  while current is SingleType(DistinguishableType(Identifier(identifier, _))) {
    let name = strip_underscore(identifier)
    assert_false(dictionary_names.contains(name))
    guard !visited.contains(name) && typedefs.get(name) is Some(typedef_) else {
      return
    }
    visited.add(name)
    current = typedef_.type_with_extended_attributes.type_
  }
  assert_false(
    current
    is SingleType(
      DistinguishableType(
        Sequence(_, _)
        | RecordType(_, _)
        | ObservableArray(_, _)
      )
    ),
  )
}
