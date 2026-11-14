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

  let dictionary_names = Set(
    definitions.filter_map(definition => {
      match definition {
        Dictionary(dictionary) => Some(strip_underscore(dictionary.identifier))
        _ => None
      }
    }),
  )

  let definition_index = Map([])
  for definition in no_name_conflict_definitions {
    if name_of_definition(definition) is Some(name) {
      definition_index.set(name, definition)
    }
  }
  for definition in definitions {
    if definition is InterfaceMixin(mixin_) {
      let name = name_of_interface_mixin(mixin_)
      match definition_index.get(name) {
        Some(
          Interface(_)
          | Dictionary(_)
          | Enum(_)
          | Callback(_)
          | CallbackInterface(_)
          | Typedef(_)
        ) => ()
        _ => definition_index.set(name, definition)
      }
    }
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
    check_type(
      attribute.type_with_extended_attributes.type_,
      typedef_index,
      dictionary_names,
      definition_index,
      allow_frozen_array=!(attribute.tag is NamespaceReadOnly),
      allow_observable_array=!(attribute.tag
        is (NamespaceReadOnly | StaticReadOnly | StaticReadWrite)),
      extended_attributes=attribute.type_with_extended_attributes.extended_attribute_list
        .iter()
        .collect(),
    )
    check_attribute_type_no_sequence(
      attribute.type_with_extended_attributes.type_,
      typedef_index,
    )
    check_attribute_type_no_async_sequence(
      attribute.type_with_extended_attributes.type_,
      typedef_index,
    )
    check_attribute_type_no_record(
      attribute.type_with_extended_attributes.type_,
      typedef_index,
    )
  }

  let dictionary_members = definitions
    .filter_map(x => {
      match x {
        Dictionary(x) =>
          Some(x.members.map(x => (x.body, x.extended_attribute_list)))
        PartialDictionary(x) =>
          Some(x.members.map(x => (x.body, x.extended_attribute_list)))
        _ => None
      }
    })
    .flatten()

  let dictionary_member_names = dictionary_members.map(member_ => {
    name_of_dictionary_member(member_.0)
  })

  for (dictionary_member, member_attributes) in dictionary_members {
    let type_ = match dictionary_member {
      Required(type_with_extended_attributes, _) =>
        type_with_extended_attributes.type_
      Optional(type_, _, _) => type_
    }
    let extended_attributes = dictionary_member_type_extended_attributes(
      dictionary_member, member_attributes,
    )
    check_type(
      type_,
      typedef_index,
      dictionary_names,
      definition_index,
      extended_attributes~,
    )
    check_type_not_nullable_dictionary(type_, typedef_index, dictionary_names)
    check_type_not_undefined(type_, typedef_index)
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
        Namespace(namespace_) =>
          Some(
            namespace_.members
            .iter()
            .filter_map(x => {
              match x.body {
                Const(c) => Some(c)
                _ => None
              }
            }),
          )
        PartialNamespace(partial_namespace) =>
          Some(
            partial_namespace.members
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
    check_type(
      operation.type_,
      typedef_index,
      dictionary_names,
      definition_index,
    )
    check_argument_types(
      operation.argument_list,
      typedef_index,
      dictionary_names,
      definition_index,
    )
  }

  let callbacks = definitions.filter_map(definition => {
    match definition {
      Callback(callback) => Some(callback)
      _ => None
    }
  })
  for callback in callbacks {
    check_type(
      callback.type_,
      typedef_index,
      dictionary_names,
      definition_index,
    )
    check_argument_types(
      callback.argument_list,
      typedef_index,
      dictionary_names,
      definition_index,
    )
  }

  for definition in definitions {
    match definition {
      Interface(interface) => {
        check_legacy_factory_function_overloads(
          interface, typedef_index, definition_index,
        )
        for attr in interface.extended_attribute_list.iter() {
          if is_valid_legacy_factory_function(attr) is Some(factory) {
            check_argument_types(
              factory.argument_list,
              typedef_index,
              dictionary_names,
              definition_index,
            )
          }
        }
        for interface_member in interface.members {
          match interface_member.body {
            Constructor(constructor_) =>
              check_argument_types(
                constructor_.argument_list,
                typedef_index,
                dictionary_names,
                definition_index,
              )
            PartialInterfaceMember(body) =>
              check_collection_types(
                body, typedef_index, dictionary_names, definition_index,
              )
          }
        }
      }
      PartialInterface(partial) =>
        for interface_member in partial.members {
          check_collection_types(
            interface_member.body,
            typedef_index,
            dictionary_names,
            definition_index,
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
    check_type(
      typedef_.type_with_extended_attributes.type_,
      typedef_index,
      dictionary_names,
      definition_index,
      allow_frozen_array=true,
      allow_observable_array=true,
      extended_attributes=typedef_.type_with_extended_attributes.extended_attribute_list
        .iter()
        .collect(),
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
    interfaces, includes_statements, interface_mixins, partial_interfaces, typedef_index,
  )
}
