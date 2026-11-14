///|
/// If the Type is an identifier or an identifier followed by ?, then the identifier
/// must identify an interface, enumeration, callback function, callback interface or typedef.
fn check_attribute_type_identifier(
  type_ : @parser.Type,
  definitions : Map[StringView, Definition],
) -> Unit raise {
  if type_ is SingleType(DistinguishableType(Identifier(identifier, _))) {
    assert_true(
      definitions.get(strip_underscore(identifier))
      is Some(
        Interface(_)
        | Enum(_)
        | Callback(_)
        | CallbackInterface(_)
        | Typedef(_)
      ),
    )
  }
}

///|
/// The identifier of an attribute must not be the same as the identifier of another
/// interface member defined on the same interface.
fn check_attribute_names_no_conflict(
  attribute_names : Array[StringView],
  other_member_names : Array[StringView],
) -> Unit raise {
  let names = Set(attribute_names)
  assert_eq(names.length(), attribute_names.length())
  assert_false(other_member_names.any(name => names.contains(name)))
}

///|
fn check_attribute_names_on_interface(interface : Interface) -> Unit raise {
  let attribute_names = []
  let other_member_names = []
  let members = interface.members.filter_map(member_ => {
    if member_.body is PartialInterfaceMember(body) {
      Some(body)
    } else {
      None
    }
  })
  for partial in interface.partials {
    members.push_iter(partial.members.iter().map(member_ => member_.body))
  }
  for member_ in members {
    if Attribute::from_partial_interface_member(member_) is Some(attribute) {
      attribute_names.push(name_of_attribute(attribute))
    } else if member_ is Const(constant) {
      other_member_names.push(strip_underscore(constant.identifier))
    } else if Operation::from_partial_interface_member(member_)
      is Some(operation) {
      if name_of_operation(operation) is Some(name) {
        other_member_names.push(name)
      }
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
    if Attribute::from_mixin_member(member_) is Some(attribute) {
      attribute_names.push(name_of_attribute(attribute))
    } else if member_ is Const(constant) {
      other_member_names.push(strip_underscore(constant.identifier))
    } else if Operation::from_interface_mixin_member(member_) is Some(operation) {
      if name_of_operation(operation) is Some(name) {
        other_member_names.push(name)
      }
    }
  }
  check_attribute_names_no_conflict(attribute_names, other_member_names)
}

///|
struct Attribute {
  name : @parser.AttributeName
  type_with_extended_attributes : @parser.TypeWithExtendedAttributes
  tag : AttributeTag
}

///|
enum AttributeTag {
  Inherit
  StaticReadOnly
  StaticReadWrite
  StringifierReadOnly
  StringifierReadWrite
  PlainReadOnly
  PlainReadWrite
  NamespaceReadOnly
}

///|
fn Attribute::from_interface_member(
  interface_member : @parser.InterfaceMember,
) -> Attribute? {
  match interface_member {
    PartialInterfaceMember(x) => Attribute::from_partial_interface_member(x)
    _ => None
  }
}

///|
fn Attribute::from_partial_interface_member(
  interface_member : @parser.PartialInterfaceMember,
) -> Attribute? {
  match interface_member {
    InheritAttribute(
      {
        attribute_rest: { type_with_extended_attributes, attribute_name: name, },
      }
    ) => Some(Attribute::{ name, type_with_extended_attributes, tag: Inherit, })
    StaticMember(
      {
        static_member_rest: Attribute(
          optional_read_only,
          { type_with_extended_attributes, attribute_name: name, }
        ),
      }
    ) =>
      Some(Attribute::{
        name,
        type_with_extended_attributes,
        tag: match optional_read_only {
          ReadOnly => StaticReadOnly
          None => StaticReadWrite
        },
      })
    Stringifier(
      {
        stringifier_rest: Attribute(
          optional_read_only,
          { type_with_extended_attributes, attribute_name: name, }
        ),
      }
    ) =>
      Some(Attribute::{
        name,
        type_with_extended_attributes,
        tag: match optional_read_only {
          ReadOnly => StringifierReadOnly
          None => StringifierReadWrite
        },
      })
    ReadOnlyMember(
      {
        read_only_member_rest: Attribute(
          { type_with_extended_attributes, attribute_name: name, }
        ),
      }
    ) =>
      Some(Attribute::{
        name,
        type_with_extended_attributes,
        tag: PlainReadOnly,
      })
    ReadWriteAttribute(
      {
        attribute_rest: { type_with_extended_attributes, attribute_name: name, },
      }
    ) =>
      Some(Attribute::{
        name,
        type_with_extended_attributes,
        tag: PlainReadWrite,
      })
    _ => None
  }
}

///|
fn Attribute::from_namespace_member(
  namespace_member : @parser.NamespaceMember,
) -> Attribute? {
  match namespace_member {
    ReadOnlyAttribute({ type_with_extended_attributes, attribute_name: name, }) =>
      Some(Attribute::{
        type_with_extended_attributes,
        name,
        tag: NamespaceReadOnly,
      })
    _ => None
  }
}

///|
fn Attribute::from_mixin_member(
  mixin_member : @parser.MixinMember,
) -> Attribute? {
  match mixin_member {
    Attribute(
      optional_read_only,
      { type_with_extended_attributes, attribute_name: name, }
    ) =>
      Some(Attribute::{
        type_with_extended_attributes,
        name,
        tag: match optional_read_only {
          ReadOnly => PlainReadOnly
          None => PlainReadWrite
        },
      })
    Stringifier(
      {
        stringifier_rest: Attribute(
          optional_read_only,
          { type_with_extended_attributes, attribute_name: name, }
        ),
      }
    ) =>
      Some(Attribute::{
        name,
        type_with_extended_attributes,
        tag: match optional_read_only {
          ReadOnly => StringifierReadOnly
          None => StringifierReadWrite
        },
      })
    _ => None
  }
}
