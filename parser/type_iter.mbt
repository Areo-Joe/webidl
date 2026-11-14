///|
/// Returns an iterator over this type and its nested types in preorder.
///
/// Yields the outer type first, then visits each nested type in declaration
/// order. For records, the key type is visited before the value type.
/// Nullable markers and repeated occurrences are preserved. Identifiers are
/// treated as leaves; typedef references are not resolved.
///
/// Yields bare `Type` values. Extended attributes attached to a union member
/// or a type's position are not carried alongside the yielded value.
///
/// # Example
/// ```mbt check
/// test {
///   let tokens = @lexer.tokenize("sequence<Promise<long?>>")
///   let (type_, rest) = Type::parse(tokens.exact_view()).unwrap()
///   assert_true(rest is [])
///   let types = type_.iter_types().collect()
///   assert_eq(types.length(), 3)
///   assert_true(types[0] is SingleType(DistinguishableType(Sequence(_, None))))
///   assert_true(types[1] is SingleType(PromiseType(_)))
///   assert_true(
///     types[2] is SingleType(DistinguishableType(PrimitiveType(_, Some))),
///   )
/// }
/// ```
pub fn Type::iter_types(self : Self) -> Iter[Type] {
  let pending = [self]
  Iter::new(fn() {
    guard pending.pop() is Some(type_) else { return None }
    match type_ {
      UnionType(union_type, _) => {
        let members = union_type.iter().collect()
        for i in 0..<members.length() {
          let union_member = members[members.length() - 1 - i]
          pending.push(
            match union_member {
              UnionType(union_type, null) => UnionType(union_type, null)
              DistinguishableTypeWithExtendedAttributeList(type_, _) =>
                SingleType(DistinguishableType(type_))
            },
          )
        }
      }
      SingleType(PromiseType(promise_type)) => pending.push(promise_type.type_)
      SingleType(DistinguishableType(type_)) =>
        match type_ {
          Sequence(inner, _)
          | AsyncSequence(inner, _)
          | FrozenArray(inner, _)
          | ObservableArray(inner, _) => pending.push(inner.type_)
          RecordType(record, _) => {
            pending.push(record.type_with_extended_attributes.type_)
            pending.push(
              SingleType(
                DistinguishableType(StringType(record.string_type, None)),
              ),
            )
          }
          PrimitiveType(_, _)
          | StringType(_, _)
          | Identifier(_, _)
          | Object(_)
          | Symbol(_)
          | BufferRelatedType(_, _)
          | Undefined(_) => ()
        }
      SingleType(Any) => ()
    }
    Some(type_)
  })
}
