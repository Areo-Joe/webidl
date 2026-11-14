///|
/// The inner type must not be:
/// * any,
/// * a promise type,
/// * an observable array type,
/// * another nullable type, or
/// * a union type that itself includes a nullable type or has a dictionary type as one of its flattened member types.
fn check_nullable_type(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
) -> Unit raise {
  for state in iter_types_resolving_typedefs(type_, typedefs) {
    let (type_, inherited_nullable) = state
    let nullable = is_nullable_type(type_)
    assert_false(inherited_nullable && nullable)
    if inherited_nullable || nullable {
      assert_false(
        type_
        is (SingleType(Any)
        | SingleType(PromiseType(_))
        | SingleType(DistinguishableType(ObservableArray(_, _)))),
      )
      if type_ is UnionType(union_type, _) {
        check_nullable_union_type(union_type, typedefs, dictionary_names)
      }
    }
  }
}

///|
fn check_nullable_union_type(
  union_type : @parser.UnionType,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
) -> Unit raise {
  let pending = union_type.iter_member_types().collect()
  let visited : Set[StringView] = Set([])
  while pending.pop() is Some(type_) {
    assert_false(is_nullable_type(type_))
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

///|
/// Although dictionary types can in general be nullable,
/// they cannot when used as the type of an operation argument or a dictionary member.
fn check_type_not_nullable_dictionary(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
) -> Unit raise {
  let mut current = type_
  let mut nullable = false
  let visited : Set[(StringView, Bool)] = Set([])
  while current is SingleType(DistinguishableType(Identifier(identifier, null))) {
    nullable = nullable || null is Some
    let name = strip_underscore(identifier)
    if dictionary_names.contains(name) {
      assert_false(nullable)
      return
    }
    guard typedefs.get(name) is Some(typedef_) else { return }
    let state = (name, nullable)
    if visited.contains(state) {
      return
    }
    visited.add(state)
    current = typedef_.type_with_extended_attributes.type_
  }
}
