///|
fn name_of_interface(interface : Interface) -> StringView {
  strip_underscore(interface.identifier)
}

///|
fn name_of_interface_mixin(interface_mixin : InterfaceMixin) -> StringView {
  strip_underscore(interface_mixin.identifier)
}

///|
fn name_of_partial_interface(
  partial_interface : PartialInterface,
) -> StringView {
  strip_underscore(partial_interface.identifier)
}

///|
fn name_of_definition(definition : Definition) -> StringView? {
  match definition.body {
    Callback({ identifier: name, .. })
    | CallbackInterface({ identifier: name, .. })
    | Namespace({ identifier: name, .. })
    | PartialInterfaceMixin({ identifier: name, .. })
    | PartialDictionary({ identifier: name, .. })
    | PartialNamespace({ identifier: name, .. })
    | Dictionary({ identifier: name, .. })
    | Enum({ identifier: name, .. })
    | Typedef({ identifier: name, .. }) => Some(strip_underscore(name))
    Interface(interface) => Some(name_of_interface(interface))
    InterfaceMixin(interface_mixin) =>
      Some(name_of_interface_mixin(interface_mixin))
    PartialInterface(partial_interface) =>
      Some(name_of_partial_interface(partial_interface))
    _ => None
  }
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

///|
fn name_of_dictionary_member(x : @parser.DictionaryMemberRest) -> StringView {
  let name = match x {
    Required(_, name) => name
    Optional(_, name, _) => name
  }

  strip_underscore(name)
}

///|
fn name_of_operation(operation : Operation) -> StringView? raise {
  guard operation.name is Some(name) else { None }

  let name = match name {
    OperationNameKeyword(Includes) => "includes"[:]
    Identifier(name) => name
  }

  let name = strip_underscore(name)

  assert_false(operation.tag is Static && name == "prototype")

  Some(name)
}
