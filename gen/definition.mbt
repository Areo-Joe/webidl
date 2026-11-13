///|
struct Definition {
  body : DefinitionBody
  extended_attribute_list : @parser.ExtendedAttributeList
}

///|
fn Definition::from_parser(
  extended_attribute_list : @parser.ExtendedAttributeList,
  definition : @parser.Definition,
) -> Self {
  Definition::{
    body: DefinitionBody::from_parser_definition(definition),
    extended_attribute_list,
  }
}

///|
enum DefinitionBody {
  Callback(Callback)
  CallbackInterface(CallbackInterface)
  Interface(Interface)
  InterfaceMixin(InterfaceMixin)
  Namespace(Namespace)
  PartialInterface(PartialInterface)
  PartialInterfaceMixin(PartialInterfaceMixin)
  PartialDictionary(@parser.PartialDictionary)
  PartialNamespace(PartialNamespace)
  Dictionary(@parser.Dictionary)
  Enum(@parser.Enum)
  Typedef(@parser.Typedef)
  IncludesStatement(@parser.IncludesStatement)
}

///|
fn DefinitionBody::from_parser_definition(
  definition : @parser.Definition,
) -> Self {
  match definition {
    CallbackOrInterfaceOrMixin(
      Callback(CallbackRest({ identifier, type_, argument_list }))
    ) => Callback(Callback::{ identifier, type_, argument_list })
    CallbackOrInterfaceOrMixin(Callback(Interface(identifier, members))) =>
      CallbackInterface(CallbackInterface::{ identifier, members })
    CallbackOrInterfaceOrMixin(
      Interface(InterfaceRest({ identifier, inheritance, interface_members }))
    ) => {
      let interface = Interface::{ identifier, inheritance, members: [] }

      let interface_members = interface_members
        .iter()
        .map(x => InterfaceMember::{
          extended_attribute_list: x.0,
          body: x.1,
          host: interface,
        })

      interface.members.push_iter(interface_members)

      Interface(interface)
    }
    CallbackOrInterfaceOrMixin(
      Interface(MixinRest({ identifier, mixin_members }))
    ) => {
      let interface_mixin = InterfaceMixin::{ identifier, members: [] }

      interface_mixin.members.push_iter(
        mixin_members
        .iter()
        .map(x => InterfaceMixinMember::{
          extended_attribute_list: x.0,
          body: x.1,
          host: interface_mixin,
        }),
      )

      InterfaceMixin(interface_mixin)
    }
    Namespace(x) => {
      let namespace_ = Namespace::{ identifier: x.identifier, members: [] }

      namespace_.members.push_iter(
        x.namespace_members
        .iter()
        .map(x => NamespaceMember::{
          extended_attribute_list: x.0,
          body: x.1,
          host: namespace_,
        }),
      )

      Namespace(namespace_)
    }
    Partial(
      {
        partial_definition: Interface(
          PartialInterfaceRest({ identifier, partial_interface_members })
        ),
      }
    ) => {
      let partial_interface = PartialInterface::{ identifier, members: [] }

      partial_interface.members.push_iter(
        partial_interface_members
        .iter()
        .map(x => PartialInterfaceMember::{
          extended_attribute_list: x.0,
          body: x.1,
          host: partial_interface,
        }),
      )

      PartialInterface(partial_interface)
    }
    Partial(
      {
        partial_definition: Interface(MixinRest({ identifier, mixin_members })),
      }
    ) => {
      let partial_interface_mixin = PartialInterfaceMixin::{
        identifier,
        members: [],
      }

      partial_interface_mixin.members.push_iter(
        mixin_members
        .iter()
        .map(x => PartialInterfaceMixinMember::{
          extended_attribute_list: x.0,
          body: x.1,
          host: partial_interface_mixin,
        }),
      )

      PartialInterfaceMixin(partial_interface_mixin)
    }
    Partial({ partial_definition: Dictionary(x) }) => PartialDictionary(x)
    Partial({ partial_definition: Namespace(x) }) => {
      let partial_namespace = PartialNamespace::{
        identifier: x.identifier,
        members: [],
      }

      partial_namespace.members.push_iter(
        x.namespace_members
        .iter()
        .map(x => PartialNamespaceMember::{
          extended_attribute_list: x.0,
          body: x.1,
          host: partial_namespace,
        }),
      )

      PartialNamespace(partial_namespace)
    }
    Dictionary(x) => Dictionary(x)
    Enum(x) => Enum(x)
    Typedef(x) => Typedef(x)
    IncludesStatement(x) => IncludesStatement(x)
  }
}

///|
struct Callback {
  identifier : StringView
  type_ : @parser.Type
  argument_list : @parser.ArgumentList
}

///|
struct CallbackInterface {
  identifier : StringView
  members : @parser.CallbackInterfaceMembers
}
