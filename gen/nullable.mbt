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
fn check_nullable_argument_types(
  arguments : @parser.ArgumentList,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
) -> Unit raise {
  for argument in arguments.iter() {
    let type_ = match argument.argument_rest {
      Optional(type_with_extended_attributes, _, _) =>
        type_with_extended_attributes.type_
      Ellipsisable(type_, _, _) => type_
    }
    check_nullable_type(type_, typedefs, dictionary_names)
  }
}

///|
fn check_nullable_collection_types(
  interface_member : @parser.PartialInterfaceMember,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
) -> Unit raise {
  match interface_member {
    Iterable({ type_with_extended_attributes, optional_type, }) => {
      check_nullable_type(
        type_with_extended_attributes.type_,
        typedefs,
        dictionary_names,
      )
      if optional_type is Some(second_type) {
        check_nullable_type(second_type.type_, typedefs, dictionary_names)
      }
    }
    AsyncIterable(
      { type_with_extended_attributes, optional_type, optional_argument_list, }
    ) => {
      check_nullable_type(
        type_with_extended_attributes.type_,
        typedefs,
        dictionary_names,
      )
      if optional_type is Some(second_type) {
        check_nullable_type(second_type.type_, typedefs, dictionary_names)
      }
      if optional_argument_list is Some(arguments) {
        check_nullable_argument_types(arguments, typedefs, dictionary_names)
      }
    }
    ReadWriteMaplike({ maplike_rest, })
    | ReadOnlyMember({ read_only_member_rest: Maplike(maplike_rest), }) => {
      check_nullable_type(
        maplike_rest.key_type.type_,
        typedefs,
        dictionary_names,
      )
      check_nullable_type(
        maplike_rest.value_type.type_,
        typedefs,
        dictionary_names,
      )
    }
    ReadWriteSetlike({ setlike_rest, })
    | ReadOnlyMember({ read_only_member_rest: Setlike(setlike_rest), }) =>
      check_nullable_type(
        setlike_rest.type_with_extended_attributes.type_,
        typedefs,
        dictionary_names,
      )
    Const(_)
    | Operation(_)
    | Stringifier(_)
    | StaticMember(_)
    | ReadOnlyMember({ read_only_member_rest: Attribute(_), })
    | ReadWriteAttribute(_)
    | InheritAttribute(_) => ()
  }
}
