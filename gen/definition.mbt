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
  Namespace(@parser.Namespace)
  PartialInterface(PartialInterface)
  PartialInterfaceMixin(PartialInterfaceMixin)
  PartialDictionary(@parser.PartialDictionary)
  PartialNamespace(@parser.Namespace)
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
    ) => InterfaceMixin(InterfaceMixin::{ identifier, members: mixin_members })
    Namespace(x) => Namespace(x)
    Partial(
      {
        partial_definition: Interface(
          PartialInterfaceRest({ identifier, partial_interface_members })
        ),
      }
    ) =>
      PartialInterface(PartialInterface::{
        identifier,
        members: partial_interface_members,
      })
    Partial(
      {
        partial_definition: Interface(MixinRest({ identifier, mixin_members })),
      }
    ) =>
      PartialInterfaceMixin(PartialInterfaceMixin::{
        identifier,
        members: mixin_members,
      })
    Partial({ partial_definition: Dictionary(x) }) => PartialDictionary(x)
    Partial({ partial_definition: Namespace(x) }) => PartialNamespace(x)
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

///|
struct InterfaceMixin {
  identifier : StringView
  members : @parser.MixinMembers
}

///|
struct PartialInterface {
  identifier : StringView
  members : @parser.PartialInterfaceMembers
}

///|
struct PartialInterfaceMixin {
  identifier : StringView
  members : @parser.MixinMembers
}
