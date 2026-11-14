///|
fn doc(definitions : @parser.Definitions) -> Unit raise {
  // The identifier of any of the abovementioned IDL constructs (except operation arguments) must not be "constructor", "toString", or begin with a U+005F (_). These are known as reserved identifiers.
  // Although the "toJSON" identifier is not a reserved identifier, it must only be used for regular operations that convert objects to JSON types, as described in § 2.5.3.1 toJSON.

  let definitions = Definition::from_parser(definitions)

  let definition_names = definitions.filter_map(name_of_definition)

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

  let dictionary_member_names = definitions
    .filter_map(x => {
      match x {
        Dictionary(x) => Some(x.members.map(x => x.body))
        PartialDictionary(x) => Some(x.members.map(x => x.body))
        _ => None
      }
    })
    .map(dictionary_members => {
      dictionary_members.iter().map(name_of_dictionary_member).collect()
    })
    .flatten()

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

  for constant in constants {
    if constant.const_type is PrimitiveType(Boolean) {
      check_boolean_constant_value(constant.const_value)
    }
    if constant.const_type is PrimitiveType(Byte) {
      check_byte_constant_value(constant.const_value)
    }
    if constant.const_type is PrimitiveType(Octet) {
      check_octet_constant_value(constant.const_value)
    }
    if constant.const_type
      is PrimitiveType(UnsignedIntegerType(IntegerType(Short))) {
      check_short_constant_value(constant.const_value)
    }
    if constant.const_type
      is PrimitiveType(UnsignedIntegerType(UnsignedIntegerType(Short))) {
      check_unsigned_short_constant_value(constant.const_value)
    }
    if constant.const_type
      is PrimitiveType(UnsignedIntegerType(IntegerType(Long(None)))) {
      check_long_constant_value(constant.const_value)
    }
  }

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
