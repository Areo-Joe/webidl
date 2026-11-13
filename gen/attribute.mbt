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
) -> Attribute raise {
  match interface_member {
    PartialInterfaceMember(
      InheritAttribute(
        {
          attribute_rest: {
            type_with_extended_attributes,
            attribute_name: name,
          },
        }
      )
    ) => Attribute::{ name, type_with_extended_attributes, tag: Inherit }
    PartialInterfaceMember(
      StaticMember(
        {
          static_member_rest: Attribute(
            optional_read_only,
            { type_with_extended_attributes, attribute_name: name }
          ),
        }
      )
    ) =>
      Attribute::{
        name,
        type_with_extended_attributes,
        tag: match optional_read_only {
          ReadOnly => StaticReadOnly
          None => StaticReadWrite
        },
      }
    PartialInterfaceMember(
      Stringifier(
        {
          stringifier_rest: Attribute(
            optional_read_only,
            { type_with_extended_attributes, attribute_name: name }
          ),
        }
      )
    ) =>
      Attribute::{
        name,
        type_with_extended_attributes,
        tag: match optional_read_only {
          ReadOnly => StringifierReadOnly
          None => StringifierReadWrite
        },
      }
    PartialInterfaceMember(
      ReadOnlyMember(
        {
          read_only_member_rest: Attribute(
            { type_with_extended_attributes, attribute_name: name }
          ),
        }
      )
    ) => Attribute::{ name, type_with_extended_attributes, tag: PlainReadOnly }
    PartialInterfaceMember(
      ReadWriteAttribute(
        {
          attribute_rest: {
            type_with_extended_attributes,
            attribute_name: name,
          },
        }
      )
    ) => Attribute::{ name, type_with_extended_attributes, tag: PlainReadWrite }
    _ => fail("not an attribute")
  }
}

///|
fn Attribute::from_namespace_member(
  namespace_member : @parser.NamespaceMember,
) -> Attribute raise {
  match namespace_member {
    ReadOnlyAttribute({ type_with_extended_attributes, attribute_name: name }) =>
      Attribute::{ type_with_extended_attributes, name, tag: PlainReadOnly }
    _ => fail("not an attribute")
  }
}
