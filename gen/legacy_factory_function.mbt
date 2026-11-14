///|
/// The [LegacyFactoryFunction] extended attribute must take a named argument list.
fn is_valid_legacy_factory_function(
  attr : @parser.ExtendedAttribute,
) -> @parser.ExtendedAttributeNamedArgList? {
  match attr {
    NamedArgList(factory) if factory.identifier == "LegacyFactoryFunction" =>
      Some(factory)
    _ => None
  }
}

///|
fn check_legacy_factory_function_overloads(
  interface : Interface,
  typedefs : Map[StringView, TypeDef],
  definitions : Map[StringView, Definition],
) -> Unit raise {
  let groups : Map[
    StringView,
    Array[(@parser.ExtendedAttribute, @parser.ArgumentList)],
  ] = Map([])
  for attr in interface.extended_attribute_list.iter() {
    if is_valid_legacy_factory_function(attr) is Some(factory) {
      let name = strip_underscore(factory.value)
      if groups.get(name) is Some(group) {
        group.push((attr, factory.argument_list))
      } else {
        groups.set(name, [(attr, factory.argument_list)])
      }
    }
  }
  for group in groups.values() {
    check_effective_overload_set(
      compute_effective_overload_set(group, 0),
      typedefs,
      definitions,
    )
  }
}
