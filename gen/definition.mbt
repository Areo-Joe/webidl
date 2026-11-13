///|
struct Interface {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  inheritance : @parser.Inheritance
  members : Array[InterfaceMember]
  partials : Array[PartialInterface]
}

///|
struct InterfaceMember {
  extended_attribute_list : @parser.ExtendedAttributeList
  body : @parser.InterfaceMember
  host : Interface
}

///|
struct InterfaceMixin {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  members : Array[InterfaceMixinMember]
  partials : Array[PartialInterfaceMixin]
}

///|
struct InterfaceMixinMember {
  extended_attribute_list : @parser.ExtendedAttributeList
  body : @parser.MixinMember
  host : InterfaceMixin
}

///|
struct PartialInterface {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  members : Array[PartialInterfaceMember]
  host : Interface
}

///|
struct PartialInterfaceMember {
  extended_attribute_list : @parser.ExtendedAttributeList
  body : @parser.PartialInterfaceMember
  host : PartialInterface
}

///|
struct PartialInterfaceMixin {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  members : Array[PartialInterfaceMixinMember]
  host : InterfaceMixin
}

///|
struct PartialInterfaceMixinMember {
  extended_attribute_list : @parser.ExtendedAttributeList
  body : @parser.MixinMember
  host : PartialInterfaceMixin
}

///|
struct Namespace {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  members : Array[NamespaceMember]
  partials : Array[PartialNamespace]
}

///|
struct NamespaceMember {
  extended_attribute_list : @parser.ExtendedAttributeList
  body : @parser.NamespaceMember
  host : Namespace
}

///|
struct PartialNamespace {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  members : Array[PartialNamespaceMember]
  host : Namespace
}

///|
struct PartialNamespaceMember {
  extended_attribute_list : @parser.ExtendedAttributeList
  body : @parser.NamespaceMember
  host : PartialNamespace
}

///|
struct Dictionary {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  inheritance : @parser.Inheritance
  members : Array[DictionaryMember]
  partials : Array[PartialDictionary]
}

///|
struct DictionaryMember {
  extended_attribute_list : @parser.ExtendedAttributeList
  body : @parser.DictionaryMemberRest
  host : Dictionary
}

///|
struct PartialDictionary {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  members : Array[PartialDictionaryMember]
  host : Dictionary
}

///|
struct PartialDictionaryMember {
  extended_attribute_list : @parser.ExtendedAttributeList
  body : @parser.DictionaryMemberRest
  host : PartialDictionary
}

///|
struct Enum {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  values : Array[StringView]
}

///|
struct TypeDef {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  type_with_extended_attributes : @parser.TypeWithExtendedAttributes
}

///|
struct IncludesStatement {
  extended_attribute_list : @parser.ExtendedAttributeList
  interface : StringView
  mixin_ : StringView
}

///|
enum Definition {
  Callback(Callback)
  CallbackInterface(CallbackInterface)
  Interface(Interface)
  InterfaceMixin(InterfaceMixin)
  Namespace(Namespace)
  PartialInterface(PartialInterface)
  PartialInterfaceMixin(PartialInterfaceMixin)
  PartialDictionary(PartialDictionary)
  PartialNamespace(PartialNamespace)
  Dictionary(Dictionary)
  Enum(Enum)
  Typedef(TypeDef)
  IncludesStatement(IncludesStatement)
}

///|
fn Definition::from_parser(definitions : @parser.Definitions) -> Array[Self] {
  let ret = definitions
    .iter()
    .filter_map(definition => {
      let (extended_attribute_list, definition) = definition
      match definition {
        CallbackOrInterfaceOrMixin(
          Callback(CallbackRest({ identifier, type_, argument_list }))
        ) =>
          Some(
            Callback(Callback::{
              identifier,
              type_,
              argument_list,
              extended_attribute_list,
            }),
          )
        CallbackOrInterfaceOrMixin(Callback(Interface(identifier, members))) =>
          Some(
            CallbackInterface(CallbackInterface::{
              identifier,
              members,
              extended_attribute_list,
            }),
          )
        CallbackOrInterfaceOrMixin(
          Interface(
            InterfaceRest({ identifier, inheritance, interface_members })
          )
        ) => {
          let interface = Interface::{
            identifier,
            inheritance,
            members: [],
            extended_attribute_list,
            partials: [],
          }

          let interface_members = interface_members
            .iter()
            .map(x => InterfaceMember::{
              extended_attribute_list: x.0,
              body: x.1,
              host: interface,
            })

          interface.members.push_iter(interface_members)

          Some(Interface(interface))
        }
        CallbackOrInterfaceOrMixin(
          Interface(MixinRest({ identifier, mixin_members }))
        ) => {
          let interface_mixin = InterfaceMixin::{
            identifier,
            members: [],
            extended_attribute_list,
            partials: [],
          }

          interface_mixin.members.push_iter(
            mixin_members
            .iter()
            .map(x => InterfaceMixinMember::{
              extended_attribute_list: x.0,
              body: x.1,
              host: interface_mixin,
            }),
          )

          Some(InterfaceMixin(interface_mixin))
        }
        Namespace(x) => {
          let namespace_ = Namespace::{
            identifier: x.identifier,
            members: [],
            extended_attribute_list,
            partials: [],
          }

          namespace_.members.push_iter(
            x.namespace_members
            .iter()
            .map(x => NamespaceMember::{
              extended_attribute_list: x.0,
              body: x.1,
              host: namespace_,
            }),
          )

          Some(Namespace(namespace_))
        }
        Dictionary(x) => {
          let dictionary = Dictionary::{
            inheritance: x.inheritance,
            identifier: x.identifier,
            members: [],
            extended_attribute_list,
            partials: [],
          }

          dictionary.members.push_iter(
            x.dictionary_members
            .iter()
            .map(x => DictionaryMember::{
              extended_attribute_list: x.extended_attribute_list,
              body: x.dictionary_member_rest,
              host: dictionary,
            }),
          )

          Some(Dictionary(dictionary))
        }
        Enum(x) =>
          Some(
            Enum(Enum::{
              identifier: x.identifier,
              values: x.enum_value_list.iter().collect(),
              extended_attribute_list,
            }),
          )
        Typedef(x) =>
          Some(
            Typedef(TypeDef::{
              type_with_extended_attributes: x.type_with_extended_attributes,
              identifier: x.identifier,
              extended_attribute_list,
            }),
          )
        IncludesStatement(x) =>
          Some(
            IncludesStatement(IncludesStatement::{
              interface: x.interface_identifier,
              mixin_: x.mixin_identifier,
              extended_attribute_list,
            }),
          )
        _ => None
      }
    })
    .collect()

  ret.push_iter(
    definitions
    .iter()
    .filter_map(definition => {
      let (extended_attribute_list, definition) = definition

      guard definition is Partial(partial) else { None }

      let partial = partial.partial_definition

      match partial {
        Interface(
          PartialInterfaceRest({ identifier, partial_interface_members })
        ) => {
          let host = ret.filter_map(x => {
              if x is Interface(x) &&
                name_of_interface(x) == strip_underscore(identifier) {
                Some(x)
              } else {
                None
              }
            })[0]

          let partial_interface = PartialInterface::{
            identifier,
            extended_attribute_list,
            members: [],
            host,
          }

          partial_interface.members.push_iter(
            partial_interface_members
            .iter()
            .map(x => PartialInterfaceMember::{
              extended_attribute_list: x.0,
              body: x.1,
              host: partial_interface,
            }),
          )

          Some(PartialInterface(partial_interface))
        }
        Interface(MixinRest({ identifier, mixin_members })) => {
          let host = ret.filter_map(x => {
              if x is InterfaceMixin(x) &&
                name_of_interface_mixin(x) == strip_underscore(identifier) {
                Some(x)
              } else {
                None
              }
            })[0]

          let partial_interface_mixin = PartialInterfaceMixin::{
            identifier,
            extended_attribute_list,
            members: [],
            host,
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

          Some(PartialInterfaceMixin(partial_interface_mixin))
        }
        Dictionary({ identifier, dictionary_members }) => {
          let host = ret.filter_map(x => {
              if x is Dictionary(inner) &&
                name_of_definition(x) is Some(name) &&
                name == strip_underscore(identifier) {
                Some(inner)
              } else {
                None
              }
            })[0]

          let partial_dictionary = PartialDictionary::{
            identifier,
            extended_attribute_list,
            members: [],
            host,
          }

          partial_dictionary.members.push_iter(
            dictionary_members
            .iter()
            .map(x => PartialDictionaryMember::{
              extended_attribute_list: x.extended_attribute_list,
              body: x.dictionary_member_rest,
              host: partial_dictionary,
            }),
          )

          Some(PartialDictionary(partial_dictionary))
        }
        Namespace({ identifier, namespace_members }) => {
          let host = ret.filter_map(x => {
              if x is Namespace(inner) &&
                name_of_definition(x) is Some(name) &&
                name == strip_underscore(identifier) {
                Some(inner)
              } else {
                None
              }
            })[0]

          let partial_namespace = PartialNamespace::{
            identifier,
            extended_attribute_list,
            members: [],
            host,
          }

          partial_namespace.members.push_iter(
            namespace_members
            .iter()
            .map(x => PartialNamespaceMember::{
              extended_attribute_list: x.0,
              body: x.1,
              host: partial_namespace,
            }),
          )

          Some(PartialNamespace(partial_namespace))
        }
      }
    }),
  )

  ret
}

///|
struct Callback {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  type_ : @parser.Type
  argument_list : @parser.ArgumentList
}

///|
struct CallbackInterface {
  extended_attribute_list : @parser.ExtendedAttributeList
  identifier : StringView
  members : @parser.CallbackInterfaceMembers
}
