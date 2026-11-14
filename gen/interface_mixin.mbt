///|
fn check_interface_mixins(
  interface_mixins : Array[InterfaceMixin],
) -> Unit raise {
  for mixin_ in interface_mixins {
    let has_cross_origin_isolated = mixin_.extended_attribute_list
      .iter()
      .any(is_valid_cross_origin_isolated)
    check_is_valid_cross_origin_isolated_on_interface_mixin(
      mixin_,
      mixin_marked=has_cross_origin_isolated,
    )
    check_cross_origin_isolated_overloads_on_interface_mixin(mixin_)
  }
}

///|
/// Note that unlike interfaces or dictionaries, interface mixins do not create types.
fn check_type_not_interface_mixin(
  type_ : @parser.Type,
  typedefs : Map[StringView, TypeDef],
  definitions : Map[StringView, Definition],
) -> Unit raise {
  for (type_, _) in iter_types_resolving_typedefs(type_, typedefs) {
    if type_ is SingleType(DistinguishableType(Identifier(name, _))) {
      assert_false(
        definitions.get(strip_underscore(name)) is Some(InterfaceMixin(_)),
      )
    }
  }
}
