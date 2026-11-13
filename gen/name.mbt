///|
fn name_of_definition(definition : Definition) -> StringView? {
  guard definition
    is (Callback({ identifier: name, .. })
    | CallbackInterface({ identifier: name, .. })
    | Interface({ identifier: name, .. })
    | InterfaceMixin({ identifier: name, .. })
    | Namespace({ identifier: name, .. })
    | PartialInterface({ identifier: name, .. })
    | PartialInterfaceMixin({ identifier: name, .. })
    | PartialDictionary({ identifier: name, .. })
    | PartialNamespace({ identifier: name, .. })
    | Dictionary({ identifier: name, .. })
    | Enum({ identifier: name, .. })
    | Typedef({ identifier: name, .. })) else {
    None
  }

  Some(strip_underscore(name))
}

///|
fn name_of_attribute(attribute : Attribute) -> StringView raise {
  let name = match attribute.name {
    AttributeNameKeyword(Required) => "required"[:]
    Identifier(name) => name
  }

  let name = strip_underscore(name)

  // The identifier of a static attribute must not be "prototype".

  if attribute.tag is (StaticReadOnly | StaticReadWrite) && name is "prototype" {
    fail("The identifier of a static attribute must not be \"prototype\".")
  }

  name
}
