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
        tag: PlainReadOnly,
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
