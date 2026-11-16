///|
/// The [PutForwards] extended attribute must take an identifier.
fn is_valid_put_forwards(attr : @parser.ExtendedAttribute) -> StringView? {
  match attr {
    Ident({ identifier: "PutForwards", value, }) => Some(value)
    _ => None
  }
}

///|
/// The [PutForwards] extended attribute must not be used on an attribute that is not read only.
/// The [PutForwards] extended attribute must not be used on a static attribute.
/// The [PutForwards] extended attribute must not be used on an attribute declared on a namespace.
/// An attribute with the [PutForwards] extended attribute must not also be declared
/// with the [LegacyLenientSetter] or [Replaceable] extended attributes.
fn check_put_forwards_placement(
  attribute : Attribute,
  extended_attributes : @parser.ExtendedAttributeList,
) -> Unit raise {
  assert_true(
    attribute.tag
    is (PlainReadOnly
    | StaticReadOnly
    | StringifierReadOnly
    | NamespaceReadOnly),
  )
  assert_false(attribute.tag is (StaticReadOnly | StaticReadWrite))
  assert_false(attribute.tag is NamespaceReadOnly)
  assert_false(
    extended_attributes
    .iter()
    .any(attr => {
      is_valid_legacy_lenient_setter(attr) || is_valid_replaceable(attr)
    }),
  )
}

///|
/// If the [PutForwards] extended attribute appears on a read only regular attribute declaration
/// whose type is an interface type, it indicates that assigning to the attribute will have
/// specific behavior. Namely, the assignment is “forwarded” to the attribute (specified by the
/// extended attribute argument) on the object that is currently referenced by the attribute being
/// assigned to.
/// Assuming that:
/// A is the attribute on which the [PutForwards] extended attribute appears,
/// I is the interface on which A is declared,
/// J is the interface type that A is declared to be of, and
/// N is the identifier argument of the extended attribute,
/// then there must be another attribute B declared on J whose identifier is N.
/// There must not exist a cycle in a chain of forwarded assignments.
fn check_put_forwards_on_interface(
  interface : Interface,
  typedefs : Map[StringView, TypeDef],
  definitions : Map[StringView, Definition],
) -> Unit raise {
  for
    (attribute, extended_attributes) in interface.attributes_with_extended_attributes() {
    for attr in extended_attributes.iter() {
      if is_valid_put_forwards(attr) is Some(target_name) {
        check_put_forwards_chain(
          interface, attribute, target_name, typedefs, definitions,
        )
      }
    }
  }
}

///|
fn interface_of_attribute_type(
  attribute : Attribute,
  typedefs : Map[StringView, TypeDef],
  definitions : Map[StringView, Definition],
) -> Interface? {
  let (type_, nullable, _) = resolve_type_with_extended_attributes(
    attribute.type_with_extended_attributes.type_,
    [],
    typedefs,
  )
  if nullable {
    return None
  }
  match type_ {
    SingleType(DistinguishableType(Identifier(name, _))) =>
      match definitions.get(strip_underscore(name)) {
        Some(Interface(interface)) => Some(interface)
        _ => None
      }
    _ => None
  }
}

///|
fn check_put_forwards_chain(
  interface : Interface,
  attribute : Attribute,
  target_name : StringView,
  typedefs : Map[StringView, TypeDef],
  definitions : Map[StringView, Definition],
) -> Unit raise {
  let mut current_interface = interface
  let mut current_attribute = attribute
  let mut current_target_name = strip_underscore(target_name)
  let visited : Set[String] = Set([])
  while true {
    let key = name_of_interface(current_interface).to_owned() +
      "#" +
      name_of_attribute(current_attribute).to_owned()
    if visited.contains(key) {
      fail("There must not exist a cycle in a chain of forwarded assignments.")
    }
    visited.add(key)
    let target_interface = match
      interface_of_attribute_type(current_attribute, typedefs, definitions) {
      Some(interface) => interface
      None => fail("J must be the interface type that A is declared to be of.")
    }
    let (target_attribute, target_extended_attributes) = match
      target_interface.attribute(current_target_name) {
      Some(target) => target
      None =>
        fail(
          "then there must be another attribute B declared on J whose identifier is N.",
        )
    }
    let mut next_target_name : StringView? = None
    for attr in target_extended_attributes.iter() {
      if is_valid_put_forwards(attr) is Some(name) {
        next_target_name = Some(name)
        break
      }
    }
    match next_target_name {
      Some(name) => {
        current_interface = target_interface
        current_attribute = target_attribute
        current_target_name = strip_underscore(name)
      }
      None => break
    }
  }
}
