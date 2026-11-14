///|
/// The inner type must not be:
/// * an observable array type,
fn check_nullable_type_no_observable_array(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  assert_false(
    iter_types_resolving_typedefs(type_, typedefs).any(state => {
      let (type_, nullable) = state
      type_ is SingleType(DistinguishableType(ObservableArray(_, _))) &&
      nullable
    }),
  )
}

///|
fn check_nullable_argument_types_no_observable_array(
  arguments : @parser.ArgumentList,
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  for argument in arguments.iter() {
    let type_ = match argument.argument_rest {
      Optional(type_with_extended_attributes, _, _) =>
        type_with_extended_attributes.type_
      Ellipsisable(type_, _, _) => type_
    }
    check_nullable_type_no_observable_array(type_, typedefs)
  }
}

///|
fn check_nullable_collection_types_no_observable_array(
  interface_member : @parser.PartialInterfaceMember,
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  match interface_member {
    Iterable({ type_with_extended_attributes, optional_type, }) => {
      check_nullable_type_no_observable_array(
        type_with_extended_attributes.type_,
        typedefs,
      )
      if optional_type is Some(second_type) {
        check_nullable_type_no_observable_array(second_type.type_, typedefs)
      }
    }
    AsyncIterable(
      { type_with_extended_attributes, optional_type, optional_argument_list, }
    ) => {
      check_nullable_type_no_observable_array(
        type_with_extended_attributes.type_,
        typedefs,
      )
      if optional_type is Some(second_type) {
        check_nullable_type_no_observable_array(second_type.type_, typedefs)
      }
      if optional_argument_list is Some(arguments) {
        check_nullable_argument_types_no_observable_array(arguments, typedefs)
      }
    }
    ReadWriteMaplike({ maplike_rest, })
    | ReadOnlyMember({ read_only_member_rest: Maplike(maplike_rest), }) => {
      check_nullable_type_no_observable_array(
        maplike_rest.key_type.type_,
        typedefs,
      )
      check_nullable_type_no_observable_array(
        maplike_rest.value_type.type_,
        typedefs,
      )
    }
    ReadWriteSetlike({ setlike_rest, })
    | ReadOnlyMember({ read_only_member_rest: Setlike(setlike_rest), }) =>
      check_nullable_type_no_observable_array(
        setlike_rest.type_with_extended_attributes.type_,
        typedefs,
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
