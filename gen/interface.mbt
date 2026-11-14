///|
fn check_interfaces(
  interfaces : Array[Interface],
  includes_statements : Array[IncludesStatement],
  interface_mixins : Array[InterfaceMixin],
  partial_interfaces : Array[PartialInterface],
  typedefs : Map[StringView, TypeDef],
) -> Unit raise {
  check_inheritance_exists(interfaces)
  check_inheritance_no_circle(interfaces)
  check_includes_valid(includes_statements, interfaces, interface_mixins)
  check_partial_interface_name(partial_interfaces, interfaces)
  check_legacy_factory_function_names(interfaces)
  check_legacy_window_alias_names(interfaces)

  let available_global_names = interfaces
    .map(interface => global_names(interface.extended_attribute_list))
    .flatten()

  for interface in interfaces {
    if interface.has_legacy_override_built_ins() {
      check_legacy_override_built_ins_interface_has_named_getter(
        interface, typedefs,
      )
    }
    if interface.extended_attribute_list
      .iter()
      .any(is_valid_legacy_no_interface_object) {
      check_legacy_no_interface_object_interface_no_constructor_or_static_operation(
        interface,
      )
    } else {
      check_interface_inheritance_no_legacy_no_interface_object(interface)
    }
    if interface.extended_attribute_list
      .iter()
      .any(attr => is_valid_legacy_factory_function(attr) is Some(_)) {
      check_legacy_factory_function_interface_no_global(interface)
    }
    check_interface_inheritance_no_global(interface)
    if interface.extended_attribute_list
      .iter()
      .any(attr => is_valid_global(attr) is Some(_)) {
      check_global_interface_no_constructor(interface)
      check_global_interface_no_named_setter(interface)
      check_global_interface_no_indexed_getter_or_setter(interface)
      check_global_interface_no_legacy_override_built_ins(interface)
      check_global_interface_inheritance_no_legacy_override_built_ins(interface)
    }
    check_exposed_global_names_on_interface(interface, available_global_names)
    let interface_exposure_set = exposure_set(
      ExposedSetStruct::Interface(interface),
      None,
    )
    let window_alias_count = interface.extended_attribute_list
      .iter()
      .filter_map(is_valid_legacy_window_alias)
      .count()
    if window_alias_count > 0 {
      check_legacy_window_alias_on_interface(
        interface, window_alias_count, interface_exposure_set,
      )
    }
    for partial in interface.partials {
      if partial.extended_attribute_list
        .iter()
        .any(is_valid_legacy_override_built_ins) {
        check_legacy_override_built_ins_partial_interface_has_named_getter(
          partial, typedefs,
        )
      }
      if partial.extended_attribute_list
        .iter()
        .any(attr => is_valid_global(attr) is Some(_)) {
        check_global_partial_interface_has_named_getter(partial, typedefs)
      }
      if ExposedAble::PartialInterface(partial).exposed_attribute()
        is Some(exposed) {
        check_exposed_partial_interface_member_no_duplicate(partial)
        check_exposed_partial_interface_is_subset_of_interface(
          exposed, interface_exposure_set,
        )
      }
    }
    check_exposed_interface_member_is_subset_of_interface(
      interface, interface_exposure_set,
    )
    check_exposed_interface_is_subset_of_inheritance(
      interface, interface_exposure_set,
    )

    let has_cross_origin_isolated = interface.extended_attribute_list
      .iter()
      .any(is_valid_cross_origin_isolated)

    let has_secure_context = interface.extended_attribute_list
      .iter()
      .any(is_valid_secure_context)
    check_is_valid_secure_context_on_interface(
      interface,
      interface_marked=has_secure_context,
    )
    if !has_secure_context {
      check_interface_inheritance_no_secure_context(interface)
    }
    check_secure_context_interface_no_cross_origin_isolated(
      interface,
      interface_marked=has_secure_context,
      interface_cross_origin_isolated=has_cross_origin_isolated,
    )
    check_secure_context_overloads_on_interface(interface)

    check_is_valid_cross_origin_isolated_on_interface(
      interface,
      interface_marked=has_cross_origin_isolated,
    )

    if !has_cross_origin_isolated {
      check_interface_inheritance_no_cross_origin_isolated(
        interfaces, interface,
      )
    }
  }
}

///|
/// An interface can be defined to inherit from another interface. If the identifier of the interface is followed by a U+003A (:) and an identifier, then that identifier identifies the inherited interface.
fn check_inheritance_exists(interfaces : Array[Interface]) -> Unit raise {
  assert_true(
    interfaces.every(interface => {
      match interface.inheritance {
        Some(inherited_interface) =>
          interfaces.search_by(i => {
            name_of_interface(i) == name_of_interface(inherited_interface)
          })
          is Some(_)
        None => true
      }
    }),
  )
}

///|
/// An interface must not be declared such that its inheritance hierarchy has a cycle. That is, an interface A cannot inherit from itself, nor can it inherit from another interface B that inherits from A, and so on.
fn check_inheritance_no_circle(interfaces : Array[Interface]) -> Unit raise {
  let visiting = Set([])
  let visited = Set([])

  fn visit_interface(interface : Interface) raise {
    let name = name_of_interface(interface)

    if visited.contains(name) {
      return
    }

    assert_false(visiting.contains(name))

    visiting.add(name)

    match interface.inheritance {
      Some(inherited_interface) => visit_interface(inherited_interface)
      None => ()
    }

    visiting.remove(name)
    visited.add(name)
  }

  for interface in interfaces {
    visit_interface(interface)
  }
}

///|
/// In addition, an includes statement can be used to define that objects implementing an interface A will always also include the members of the interface mixins A includes.
fn check_includes_valid(
  includes_statements : Array[IncludesStatement],
  interfaces : Array[Interface],
  interface_mixins : Array[InterfaceMixin],
) -> Unit raise {
  assert_true(
    includes_statements.every(includes_statement => {
      let { interface, mixin_, .. } = includes_statement

      let interface_identifier = strip_underscore(interface)
      let mixin_identifier = strip_underscore(mixin_)

      interfaces.search_by(interface => {
        name_of_interface(interface) == interface_identifier
      })
      is Some(_) &&
      interface_mixins.search_by(interface_mixin => {
        name_of_interface_mixin(interface_mixin) == mixin_identifier
      })
      is Some(_)
    }),
  )
}

///|
/// The identifier of a partial interface definition must be the same as the identifier of an interface definition.
fn check_partial_interface_name(
  partial_interfaces : Array[PartialInterface],
  interfaces : Array[Interface],
) -> Unit raise {
  assert_true(
    partial_interfaces.every(partial_interface => {
      let name = name_of_partial_interface(partial_interface)
      interfaces.search_by(x => name_of_interface(x) == name) is Some(_)
    }),
  )
}
