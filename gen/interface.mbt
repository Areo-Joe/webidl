///|
fn check_interfaces(
  interfaces : Array[Interface],
  includes_statements : Array[IncludesStatement],
  interface_mixins : Array[InterfaceMixin],
  partial_interfaces : Array[PartialInterface],
) -> Unit raise {
  check_inheritance_exists(interfaces)
  check_inheritance_no_circle(interfaces)
  check_includes_valid(includes_statements, interfaces, interface_mixins)
  check_partial_interface_name(partial_interfaces, interfaces)

  for interface in interfaces {
    // let (extended_attribute_list, interface) = interface

    let mut has_cross_origin_isolated = false

    for extended_attribute in interface.extended_attribute_list.iter() {
      if is_valid_cross_origin_isolated(extended_attribute) {
        has_cross_origin_isolated = true

        check_is_valid_cross_origin_isolated_on_interface(interface)
      }
    }

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
