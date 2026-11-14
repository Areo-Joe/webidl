///|
fn nullable_union_member_type_count(
  type_ : @parser.Type,
  typedef_nullable_counts : Map[StringView, Int32],
) -> Int32 {
  let nullable = if is_nullable_type(type_) { 1 } else { 0 }
  let inner_count = match type_ {
    UnionType(union_type, _) =>
      number_of_nullable_member_types(union_type, typedef_nullable_counts)
    SingleType(DistinguishableType(Identifier(identifier, _))) =>
      typedef_nullable_counts.get(strip_underscore(identifier)).unwrap_or(0)
    _ => 0
  }
  nullable + inner_count
}

///|
fn number_of_nullable_member_types(
  union_type : @parser.UnionType,
  typedef_nullable_counts : Map[StringView, Int32],
) -> Int32 {
  let mut count = 0
  for type_ in union_type.iter_member_types() {
    count += nullable_union_member_type_count(type_, typedef_nullable_counts)
  }
  count
}

///|
/// The any type must not be used as a union member type.
/// The number of nullable member types of a union type must
/// be 0 or 1, and if it is 1 then the union type must also not have
/// a dictionary type in its flattened member types.
fn check_union_type(
  union_type : @parser.UnionType,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
  definitions : Map[StringView, Definition],
) -> Unit raise {
  let pending = union_type.iter_member_types().collect()
  let references : Array[TypeDef] = []
  let typedef_nullable_counts : Map[StringView, Int32] = Map([])
  let mut has_dictionary = false
  while pending.pop() is Some(type_) {
    assert_false(type_ is SingleType(Any))
    match type_ {
      UnionType(union_type, _) =>
        pending.push_iter(union_type.iter_member_types())
      SingleType(DistinguishableType(Identifier(identifier, _))) => {
        let name = strip_underscore(identifier)
        if dictionary_names.contains(name) {
          has_dictionary = true
        }
        if typedef_nullable_counts.get(name) is None &&
          typedefs.get(name) is Some(typedef_) {
          typedef_nullable_counts.set(name, 0)
          references.push(typedef_)
          pending.push(typedef_.type_with_extended_attributes.type_)
        }
      }
      _ => ()
    }
  }

  let mut changed = true
  while changed {
    changed = false
    for typedef_ in references {
      let name = strip_underscore(typedef_.identifier)
      let count = nullable_union_member_type_count(
        typedef_.type_with_extended_attributes.type_,
        typedef_nullable_counts,
      )
      assert_true(count <= 1)
      if typedef_nullable_counts.get(name) != Some(count) {
        typedef_nullable_counts.set(name, count)
        changed = true
      }
    }
    let count = number_of_nullable_member_types(
      union_type, typedef_nullable_counts,
    )
    assert_true(count <= 1)
    if count == 1 {
      assert_false(has_dictionary)
    }
  }
  check_union_member_types_distinguishable(union_type, typedefs, definitions)
}

///|
/// The flattened member types of a union type, possibly annotated, is a set of types determined as follows:
fn flattened_member_types(
  union_type : @parser.UnionType,
  typedefs : Map[StringView, TypeDef],
) -> Array[@parser.Type] {
  let pending = union_type.iter_member_types().collect()
  let visited : Set[StringView] = Set([])
  let members : Array[@parser.Type] = []
  while pending.pop() is Some(type_) {
    match type_ {
      UnionType(union_type, _) =>
        pending.push_iter(union_type.iter_member_types())
      SingleType(DistinguishableType(Identifier(name, _))) if typedefs.get(
          strip_underscore(name),
        )
        is Some(typedef_) => {
        let name = strip_underscore(name)
        if !visited.contains(name) {
          visited.add(name)
          pending.push(typedef_.type_with_extended_attributes.type_)
        }
      }
      _ =>
        if !members.any(existing => {
            same_flattened_member_type(existing, type_, typedefs)
          }) {
          members.push(type_)
        }
    }
  }
  members
}

///|
/// Each pair of flattened member types in a union type, T and U, must be distinguishable.
fn check_union_member_types_distinguishable(
  union_type : @parser.UnionType,
  typedefs : Map[StringView, TypeDef],
  definitions : Map[StringView, Definition],
) -> Unit raise {
  let members = flattened_member_types(union_type, typedefs)
  for i in 0..<members.length() {
    for j in 0..<i {
      assert_true(
        are_flattened_member_types_distinguishable(
          members[i],
          members[j],
          definitions,
        ),
      )
    }
  }
}
