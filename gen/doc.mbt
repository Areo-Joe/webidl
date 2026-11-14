///|
fn doc(definitions : @parser.Definitions) -> Unit raise {
  // The identifier of any of the abovementioned IDL constructs (except operation arguments) must not be "constructor", "toString", or begin with a U+005F (_). These are known as reserved identifiers.
  // Although the "toJSON" identifier is not a reserved identifier, it must only be used for regular operations that convert objects to JSON types, as described in § 2.5.3.1 toJSON.

  let definitions = Definition::from_parser(definitions)

  let definition_names = definitions.filter_map(name_of_definition)

  // Within the set of IDL fragments that a given implementation supports, the identifier of every interface, namespace, dictionary, enumeration, callback function, callback interface and typedef must not be the same as the identifier of any other interface, namespace, dictionary, enumeration, callback function, callback interface or typedef.
  let no_name_conflict_definitions = definitions.filter_map(x => {
    match x {
      Interface(_)
      | Callback(_)
      | Namespace(_)
      | Dictionary(_)
      | Enum(_)
      | CallbackInterface(_)
      | Typedef(_) => Some(x)
      _ => None
    }
  })

  let no_conflict_names = no_name_conflict_definitions.filter_map(
    name_of_definition,
  )

  assert_eq(no_conflict_names.length(), Set(no_conflict_names).length())

  let typedefs = definitions.filter_map(x => {
    match x {
      Typedef(typedef_) => Some(typedef_)
      _ => None
    }
  })
  check_typedef_type_not_typedef(typedefs)

  let typedef_index = Map([])
  for typedef_ in typedefs {
    typedef_index.set(strip_underscore(typedef_.identifier), typedef_)
  }

  let attributes = definitions
    .map(definition => {
      match definition {
        Interface(interface) =>
          interface.members
          .iter()
          .filter_map(x => Attribute::from_interface_member(x.body))
          .collect()
        InterfaceMixin(interface_mixin) =>
          interface_mixin.members
          .iter()
          .filter_map(x => Attribute::from_mixin_member(x.body))
          .collect()
        PartialInterface(interface) =>
          interface.members
          .iter()
          .filter_map(x => Attribute::from_partial_interface_member(x.body))
          .collect()
        PartialInterfaceMixin(partial_interface_mixin) =>
          partial_interface_mixin.members
          .iter()
          .filter_map(x => Attribute::from_mixin_member(x.body))
          .collect()
        Namespace(x) =>
          x.members
          .iter()
          .filter_map(x => Attribute::from_namespace_member(x.body))
          .collect()
        PartialNamespace(x) =>
          x.members
          .iter()
          .filter_map(x => Attribute::from_namespace_member(x.body))
          .collect()
        _ => []
      }
    })
    .flatten()

  let attribute_names = attributes.map(name_of_attribute)

  for attribute in attributes {
    check_nullable_type_no_observable_array(
      attribute.type_with_extended_attributes.type_,
      typedef_index,
    )
  }

  let dictionary_members = definitions
    .filter_map(x => {
      match x {
        Dictionary(x) => Some(x.members.map(x => x.body))
        PartialDictionary(x) => Some(x.members.map(x => x.body))
        _ => None
      }
    })
    .flatten()

  let dictionary_member_names = dictionary_members.map(
    name_of_dictionary_member,
  )

  for dictionary_member in dictionary_members {
    let type_ = match dictionary_member {
      Required(type_with_extended_attributes, _) =>
        type_with_extended_attributes.type_
      Optional(type_, _, _) => type_
    }
    check_nullable_type_no_observable_array(type_, typedef_index)
  }

  let constants = definitions
    .filter_map(x => {
      match x {
        Interface(interface) =>
          Some(
            interface.members
            .iter()
            .filter_map(x => {
              match x.body {
                PartialInterfaceMember(Const(c)) => Some(c)
                _ => None
              }
            }),
          )
        PartialInterface(partial_interface) =>
          Some(
            partial_interface.members
            .iter()
            .filter_map(x => {
              match x.body {
                Const(c) => Some(c)
                _ => None
              }
            }),
          )
        InterfaceMixin(interface_mixin) =>
          Some(
            interface_mixin.members
            .iter()
            .filter_map(x => {
              match x.body {
                Const(c) => Some(c)
                _ => None
              }
            }),
          )
        PartialInterfaceMixin(partial_interface_mixin) =>
          Some(
            partial_interface_mixin.members
            .iter()
            .filter_map(x => {
              match x.body {
                Const(c) => Some(c)
                _ => None
              }
            }),
          )
        CallbackInterface(callback_interface) =>
          Some(
            callback_interface.members
            .iter()
            .filter_map(x => {
              match x.1 {
                Const(c) => Some(c)
                _ => None
              }
            }),
          )
        _ => None
      }
    })
    .map(x => x.collect())
    .flatten()

  let constant_names = constants.map(x => strip_underscore(x.identifier))

  let operations = definitions
    .filter_map(definition => {
      match definition {
        Interface(interface) =>
          Some(
            interface.members
            .iter()
            .filter_map(x => Operation::from_interface_member(x)),
          )
        PartialInterface(partial_interface) =>
          Some(
            partial_interface.members
            .iter()
            .filter_map(x => Operation::from_partial_interface_member(x.body)),
          )
        InterfaceMixin(interface_mixin) =>
          Some(
            interface_mixin.members
            .iter()
            .filter_map(x => Operation::from_interface_mixin_member(x.body)),
          )
        PartialInterfaceMixin(partial_interface_mixin) =>
          Some(
            partial_interface_mixin.members
            .iter()
            .filter_map(x => Operation::from_interface_mixin_member(x.body)),
          )
        Namespace(namespace_) =>
          Some(
            namespace_.members
            .iter()
            .filter_map(x => Operation::from_namespace_member(x.body)),
          )
        PartialNamespace(namespace_) =>
          Some(
            namespace_.members
            .iter()
            .filter_map(x => Operation::from_namespace_member(x.body)),
          )
        CallbackInterface(callback_interface) =>
          Some(
            callback_interface.members
            .iter()
            .filter_map(x => Operation::from_callback_interface_member(x.1)),
          )
        _ => None
      }
    })
    .map(x => x.collect())
    .flatten()

  let operation_names = operations.filter_map(name_of_operation)

  for operation in operations {
    check_nullable_type_no_observable_array(operation.type_, typedef_index)
    check_nullable_argument_types_no_observable_array(
      operation.argument_list,
      typedef_index,
    )
  }

  let callbacks = definitions.filter_map(definition => {
    match definition {
      Callback(callback) => Some(callback)
      _ => None
    }
  })
  for callback in callbacks {
    check_nullable_type_no_observable_array(callback.type_, typedef_index)
    check_nullable_argument_types_no_observable_array(
      callback.argument_list,
      typedef_index,
    )
  }

  for definition in definitions {
    match definition {
      Interface(interface) => {
        for attr in interface.extended_attribute_list.iter() {
          if attr
            is NamedArgList(
              { identifier: "LegacyFactoryFunction", argument_list, .. }
            ) {
            check_nullable_argument_types_no_observable_array(
              argument_list, typedef_index,
            )
          }
        }
        for interface_member in interface.members {
          match interface_member.body {
            Constructor(constructor_) =>
              check_nullable_argument_types_no_observable_array(
                constructor_.argument_list,
                typedef_index,
              )
            PartialInterfaceMember(body) =>
              check_nullable_collection_types_no_observable_array(
                body, typedef_index,
              )
          }
        }
      }
      PartialInterface(partial) =>
        for interface_member in partial.members {
          check_nullable_collection_types_no_observable_array(
            interface_member.body,
            typedef_index,
          )
        }
      _ => ()
    }
  }

  let operations_not_regular = operations.filter_map(x => {
    match x.tag {
      Regular => None
      _ => Some(x)
    }
  })

  let operation_names_not_regular = operations_not_regular.filter_map(
    name_of_operation,
  )

  // The identifier of any of the abovementioned IDL constructs (except operation arguments) must not be "constructor", "toString", or begin with a U+005F (_). These are known as reserved identifiers.
  assert_true(
    (definition_names +
    attribute_names +
    dictionary_member_names +
    constant_names +
    operation_names).every(name => {
      name != "constructor" && name != "toString" && !name.has_prefix("_")
    }),
  )

  // Although the "toJSON" identifier is not a reserved identifier, it must only be used for regular operations that convert objects to JSON types, as described in § 2.5.3.1 toJSON.
  assert_true(
    (definition_names +
    attribute_names +
    dictionary_member_names +
    constant_names +
    operation_names_not_regular).every(name => name != "toJSON"),
  )

  for typedef_ in typedefs {
    check_nullable_type_no_observable_array(
      typedef_.type_with_extended_attributes.type_,
      typedef_index,
    )
  }
  for constant in constants {
    let primitive_type = primitive_type_of_constant(
      constant.const_type,
      typedefs,
    )
    check_constant_value(primitive_type, constant.const_value)
  }

  let interfaces = definitions.filter_map(x => {
    match x {
      Interface(interface) => Some(interface)
      _ => None
    }
  })
  let interface_mixins = definitions.filter_map(x => {
    match x {
      InterfaceMixin(i) => Some(i)
      _ => None
    }
  })
  let partial_interfaces = definitions.filter_map(x => {
    match x {
      PartialInterface(i) => Some(i)
      _ => None
    }
  })
  let includes_statements = definitions.filter_map(x => {
    match x {
      IncludesStatement(i) => Some(i)
      _ => None
    }
  })

  check_interfaces(
    interfaces, includes_statements, interface_mixins, partial_interfaces,
  )
}
