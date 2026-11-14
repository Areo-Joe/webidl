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

///|
fn check_type(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
  definitions : Map[StringView, Definition],
  extended_attributes~ : Array[@parser.ExtendedAttribute] = [],
) -> Unit raise {
  check_annotated_type(type_, extended_attributes, typedefs)
  check_nullable_type(type_, typedefs, dictionary_names)
  for state in iter_types_resolving_typedefs(type_, typedefs) {
    if state.0 is UnionType(union_type, _) {
      check_union_type(union_type, typedefs, dictionary_names, definitions)
    }
  }
}

///|
fn check_argument_types(
  arguments : @parser.ArgumentList,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
  definitions : Map[StringView, Definition],
) -> Unit raise {
  for argument in arguments.iter() {
    let type_ = match argument.argument_rest {
      Optional(type_with_extended_attributes, _, _) =>
        type_with_extended_attributes.type_
      Ellipsisable(type_, _, _) => type_
    }
    let extended_attributes = argument_type_extended_attributes(argument)
    check_type(
      type_,
      typedefs,
      dictionary_names,
      definitions,
      extended_attributes~,
    )
    check_type_not_nullable_dictionary(type_, typedefs, dictionary_names)
  }
}

///|
fn check_collection_types(
  interface_member : @parser.PartialInterfaceMember,
  typedefs : Map[StringView, TypeDef],
  dictionary_names : Set[StringView],
  definitions : Map[StringView, Definition],
) -> Unit raise {
  match interface_member {
    Iterable({ type_with_extended_attributes, optional_type, }) => {
      check_type(
        type_with_extended_attributes.type_,
        typedefs,
        dictionary_names,
        definitions,
        extended_attributes=type_with_extended_attributes.extended_attribute_list
          .iter()
          .collect(),
      )
      if optional_type is Some(second_type) {
        check_type(
          second_type.type_,
          typedefs,
          dictionary_names,
          definitions,
          extended_attributes=second_type.extended_attribute_list
            .iter()
            .collect(),
        )
      }
    }
    AsyncIterable(
      { type_with_extended_attributes, optional_type, optional_argument_list, }
    ) => {
      check_type(
        type_with_extended_attributes.type_,
        typedefs,
        dictionary_names,
        definitions,
        extended_attributes=type_with_extended_attributes.extended_attribute_list
          .iter()
          .collect(),
      )
      if optional_type is Some(second_type) {
        check_type(
          second_type.type_,
          typedefs,
          dictionary_names,
          definitions,
          extended_attributes=second_type.extended_attribute_list
            .iter()
            .collect(),
        )
      }
      if optional_argument_list is Some(arguments) {
        check_argument_types(arguments, typedefs, dictionary_names, definitions)
      }
    }
    ReadWriteMaplike({ maplike_rest, })
    | ReadOnlyMember({ read_only_member_rest: Maplike(maplike_rest), }) => {
      check_type(
        maplike_rest.key_type.type_,
        typedefs,
        dictionary_names,
        definitions,
        extended_attributes=maplike_rest.key_type.extended_attribute_list
          .iter()
          .collect(),
      )
      check_type(
        maplike_rest.value_type.type_,
        typedefs,
        dictionary_names,
        definitions,
        extended_attributes=maplike_rest.value_type.extended_attribute_list
          .iter()
          .collect(),
      )
    }
    ReadWriteSetlike({ setlike_rest, })
    | ReadOnlyMember({ read_only_member_rest: Setlike(setlike_rest), }) =>
      check_type(
        setlike_rest.type_with_extended_attributes.type_,
        typedefs,
        dictionary_names,
        definitions,
        extended_attributes=setlike_rest.type_with_extended_attributes.extended_attribute_list
          .iter()
          .collect(),
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
