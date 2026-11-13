///|
enum Definition {
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
fn Definition::from_parser_definition(definition : @parser.Definition) -> Self {
  match definition {
    CallbackOrInterfaceOrMixin(
      Callback(CallbackRest({ identifier, type_, argument_list }))
    ) => Definition::Callback(Callback::{ identifier, type_, argument_list })
    CallbackOrInterfaceOrMixin(Callback(Interface(identifier, members))) =>
      Definition::CallbackInterface(CallbackInterface::{ identifier, members })
    CallbackOrInterfaceOrMixin(
      Interface(InterfaceRest({ identifier, inheritance, interface_members }))
    ) =>
      Definition::Interface(Interface::{
        identifier,
        inheritance,
        members: interface_members,
      })
    CallbackOrInterfaceOrMixin(
      Interface(MixinRest({ identifier, mixin_members }))
    ) =>
      Definition::InterfaceMixin(InterfaceMixin::{
        identifier,
        members: mixin_members,
      })
    Namespace(x) => Definition::Namespace(x)
    Partial(
      {
        partial_definition: Interface(
          PartialInterfaceRest({ identifier, partial_interface_members })
        ),
      }
    ) =>
      Definition::PartialInterface(PartialInterface::{
        identifier,
        members: partial_interface_members,
      })
    Partial(
      {
        partial_definition: Interface(MixinRest({ identifier, mixin_members })),
      }
    ) =>
      Definition::PartialInterfaceMixin(PartialInterfaceMixin::{
        identifier,
        members: mixin_members,
      })
    Partial({ partial_definition: Dictionary(x) }) =>
      Definition::PartialDictionary(x)
    Partial({ partial_definition: Namespace(x) }) =>
      Definition::PartialNamespace(x)
    Dictionary(x) => Definition::Dictionary(x)
    Enum(x) => Definition::Enum(x)
    Typedef(x) => Definition::Typedef(x)
    IncludesStatement(x) => Definition::IncludesStatement(x)
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
struct Interface {
  identifier : StringView
  inheritance : @parser.Inheritance
  members : @parser.InterfaceMembers
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
