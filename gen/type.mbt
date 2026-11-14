///|
fn is_nullable_type(type_ : @parser.Type) -> Bool {
  match type_ {
    UnionType(_, null) => null is Some
    SingleType(DistinguishableType(type_)) =>
      match type_ {
        PrimitiveType(_, null)
        | StringType(_, null)
        | Identifier(_, null)
        | Sequence(_, null)
        | AsyncSequence(_, null)
        | Object(null)
        | Symbol(null)
        | BufferRelatedType(_, null)
        | FrozenArray(_, null)
        | ObservableArray(_, null)
        | RecordType(_, null)
        | Undefined(null) => null is Some
      }
    SingleType(Any) | SingleType(PromiseType(_)) => false
  }
}

///|
fn iter_types_resolving_typedefs(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
) -> Iter[(@parser.Type, Bool)] {
  let pending = [(type_.iter_types(), false)]
  let visited : Set[(StringView, Bool)] = Set([])
  Iter::new(fn() {
    while pending.pop() is Some((types, inherited_nullable)) {
      guard types.next() is Some(type_) else { continue }
      pending.push((types, false))
      let nullable = inherited_nullable || is_nullable_type(type_)
      if type_ is SingleType(DistinguishableType(Identifier(identifier, _))) {
        let name = strip_underscore(identifier)
        if typedefs.get(name) is Some(typedef_) {
          let state = (name, nullable)
          if !visited.contains(state) {
            visited.add(state)
            pending.push(
              (
                typedef_.type_with_extended_attributes.type_.iter_types(),
                nullable,
              ),
            )
          }
        }
      }
      return Some((type_, inherited_nullable))
    }
    None
  })
}
