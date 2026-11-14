///|
priv enum Global {
  Ident(StringView)
  IdentList(Array[StringView])
}

///|
/// The [Global] extended attribute also defines the global names for the interface:
///
/// If the [Global] extended attribute takes an identifier
/// « the given identifier »
///
/// If the [Global] extended attribute takes an identifier list
/// the identifier list
///
/// The [Global] extended attribute must be one of the forms given above.
fn is_valid_global(attr : @parser.ExtendedAttribute) -> Global? {
  match attr {
    Ident({ identifier: "Global", value, }) => Some(Ident(value))
    IdentList({ identifier: "Global", identifier_list, }) =>
      Some(IdentList(identifier_list.iter().collect()))
    _ => None
  }
}

///|
fn global_names(attr_list : @parser.ExtendedAttributeList) -> Array[StringView] {
  attr_list
  .iter()
  .filter_map(is_valid_global)
  .map(x => {
    match x {
      Ident(value) => [strip_underscore(value)]
      IdentList(identifier_list) => identifier_list.map(strip_underscore)
    }
  })
  .collect()
  .flatten()
}

///|
/// If an interface is declared with the [Global] extended attribute, then there
/// must not be more than one member across the interface with the same identifier.
/// There also must not be more than one stringifier or more than one iterable
/// declaration, asynchronously iterable declaration, maplike declaration or
/// setlike declaration across those interfaces.
fn check_global_interface_members_unique(interface : Interface) -> Unit raise {
  let members = interface.members.filter_map(member_ => {
    match member_.body {
      PartialInterfaceMember(body) => Some(body)
      Constructor(_) => None
    }
  })
  for partial in interface.partials {
    members.push_iter(partial.members.iter().map(member_ => member_.body))
  }
  let names : Set[StringView] = Set([])
  let mut stringifiers = 0
  let mut collections = 0
  for member_ in members {
    let name = if member_ is Const(constant) {
      Some(strip_underscore(constant.identifier))
    } else if Attribute::from_partial_interface_member(member_)
      is Some(attribute) {
      Some(name_of_attribute(attribute))
    } else if Operation::from_partial_interface_member(member_)
      is Some(operation) {
      name_of_operation(operation)
    } else {
      None
    }
    if name is Some(name) {
      assert_false(names.contains(name))
      names.add(name)
    }
    match member_ {
      Stringifier(_) => stringifiers = stringifiers + 1
      Iterable(_)
      | AsyncIterable(_)
      | ReadWriteMaplike(_)
      | ReadWriteSetlike(_)
      | ReadOnlyMember({ read_only_member_rest: Maplike(_) | Setlike(_), }) =>
        collections = collections + 1
      _ => ()
    }
  }
  let mixin_members = []
  for mixin_ in interface.mixins {
    mixin_members.push_iter(mixin_.members.iter().map(member_ => member_.body))
    for partial in mixin_.partials {
      mixin_members.push_iter(
        partial.members.iter().map(member_ => member_.body),
      )
    }
  }
  for member_ in mixin_members {
    let name = if member_ is Const(constant) {
      Some(strip_underscore(constant.identifier))
    } else if Attribute::from_mixin_member(member_) is Some(attribute) {
      Some(name_of_attribute(attribute))
    } else if Operation::from_interface_mixin_member(member_) is Some(operation) {
      name_of_operation(operation)
    } else {
      None
    }
    if name is Some(name) {
      assert_false(names.contains(name))
      names.add(name)
    }
    if member_ is Stringifier(_) {
      stringifiers = stringifiers + 1
    }
  }
  assert_true(stringifiers <= 1)
  assert_true(collections <= 1)
}

///|
/// If the [Global] extended attributes is used on an interface, then:
/// The interface must not define a constructor operation.
fn check_global_interface_no_constructor(interface : Interface) -> Unit raise {
  assert_false(
    interface.members
    .iter()
    .any(interface_member => {
      interface_member.body is @parser.InterfaceMember::Constructor(_)
    }),
  )
}

///|
/// If the [Global] extended attributes is used on an interface, then:
/// The interface must not also be declared with the [LegacyOverrideBuiltIns] extended attribute.
fn check_global_interface_no_legacy_override_built_ins(
  interface : Interface,
) -> Unit raise {
  assert_false(interface.has_legacy_override_built_ins())
}

///|
/// If the [Global] extended attributes is used on an interface, then:
/// The interface must not inherit from another interface with the [LegacyOverrideBuiltIns] extended attribute.
fn check_global_interface_inheritance_no_legacy_override_built_ins(
  interface : Interface,
) -> Unit raise {
  guard interface.inheritance is Some(inheritance) else { return }
  assert_false(inheritance.has_legacy_override_built_ins())
  check_global_interface_inheritance_no_legacy_override_built_ins(inheritance)
}

///|
/// If the [Global] extended attributes is used on an interface, then:
/// Any other interface must not inherit from it.
fn check_interface_inheritance_no_global(interface : Interface) -> Unit raise {
  guard interface.inheritance is Some(inheritance) else { return }
  assert_false(
    inheritance.extended_attribute_list
    .iter()
    .any(attr => is_valid_global(attr) is Some(_)),
  )
  check_interface_inheritance_no_global(inheritance)
}

///|
/// If the [Global] extended attributes is used on an interface, then:
/// The interface must not define a named property setter.
fn check_global_interface_no_named_setter(
  interface : Interface,
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  let operations = interface.members.filter_map(
    Operation::from_interface_member,
  )
  for partial in interface.partials {
    operations.push_iter(
      partial.members
      .iter()
      .filter_map(interface_member => {
        Operation::from_partial_interface_member(interface_member.body)
      }),
    )
  }
  assert_false(
    operations
    .iter()
    .any(operation => {
      guard operation.tag is Setter else { return false }
      guard operation.argument_list
        is Some({ argument_rest, .. }, Some(_, None)) else {
        return false
      }
      let type_ = match argument_rest {
        Ellipsisable(type_, _, _) => type_
        Optional({ type_, .. }, _, _) => type_
      }
      let (type_, nullable, _) = resolve_type_with_extended_attributes(
        type_,
        [],
        typedefs,
      )
      !nullable &&
      type_ is SingleType(DistinguishableType(StringType(DOMString, _)))
    }),
  )
}

///|
/// If the [Global] extended attributes is used on an interface, then:
/// The interface must not define indexed property getters or setters.
fn check_global_interface_no_indexed_getter_or_setter(
  interface : Interface,
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  let operations = interface.members.filter_map(
    Operation::from_interface_member,
  )
  for partial in interface.partials {
    operations.push_iter(
      partial.members
      .iter()
      .filter_map(interface_member => {
        Operation::from_partial_interface_member(interface_member.body)
      }),
    )
  }
  assert_false(
    operations
    .iter()
    .any(operation => {
      let argument_rest = match (operation.tag, operation.argument_list) {
        (Getter, Some(first, None)) | (Setter, Some(first, Some(_, None))) =>
          first.argument_rest
        _ => return false
      }
      let type_ = match argument_rest {
        Ellipsisable(type_, _, _) => type_
        Optional({ type_, .. }, _, _) => type_
      }
      let (type_, nullable, _) = resolve_type_with_extended_attributes(
        type_,
        [],
        typedefs,
      )
      !nullable &&
      type_
      is SingleType(
        DistinguishableType(
          PrimitiveType(UnsignedIntegerType(UnsignedIntegerType(Long(None))), _)
        )
      )
    }),
  )
}

///|
/// If [Global] is specified on a partial interface definition, then that partial interface definition must be the part of the interface definition that defines the named property getter.
fn check_global_partial_interface_has_named_getter(
  partial : PartialInterface,
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  assert_true(
    partial.members
    .iter()
    .filter_map(interface_member => {
      Operation::from_partial_interface_member(interface_member.body)
    })
    .any(operation => operation.is_named_getter(typedefs)),
  )
}
