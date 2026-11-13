///|
fn doc(definitions : @parser.Definitions) -> Unit raise {
  // The identifier of any of the abovementioned IDL constructs (except operation arguments) must not be "constructor", "toString", or begin with a U+005F (_). These are known as reserved identifiers.

  // Although the "toJSON" identifier is not a reserved identifier, it must only be used for regular operations that convert objects to JSON types, as described in § 2.5.3.1 toJSON.

  let definitions = definitions
    .iter()
    .map(x => Definition::from_parser_definition(x.1))
    .collect()

  let definition_names = definitions.filter_map(name_of_definition)

  let attributes = definitions
    .map(definition => {
      match definition {
        Interface(interface) =>
          interface.members
          .iter()
          .filter_map(x => Attribute::from_interface_member(x.1))
          .collect()
        InterfaceMixin(interface_mixin) =>
          interface_mixin.members
          .iter()
          .filter_map(x => Attribute::from_mixin_member(x.1))
          .collect()
        PartialInterface(interface) =>
          interface.members
          .iter()
          .filter_map(x => Attribute::from_partial_interface_member(x.1))
          .collect()
        PartialInterfaceMixin(partial_interface_mixin) =>
          partial_interface_mixin.members
          .iter()
          .filter_map(x => Attribute::from_mixin_member(x.1))
          .collect()
        Namespace(namespace_) | PartialNamespace(namespace_) =>
          namespace_.namespace_members
          .iter()
          .filter_map(x => Attribute::from_namespace_member(x.1))
          .collect()
        _ => []
      }
    })
    .flatten()

  let attribute_names = attributes.map(name_of_attribute)

  let dictionary_member_names = definitions
    .filter_map(x => {
      match x {
        Dictionary(x) => Some(x.dictionary_members)
        PartialDictionary(x) => Some(x.dictionary_members)
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
              match x.1 {
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
              match x.1 {
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
              match x.1 {
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
              match x.1 {
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

  let constant_names = constants.map(x => x.identifier)
  
  
}
