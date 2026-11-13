///|
fn check_interfaces(interfaces : Array[Interface]) -> Unit raise {
  check_inheritance_exists(interfaces)
  check_inheritance_no_circle(interfaces)
}

///|
/// An interface can be defined to inherit from another interface. If the identifier of the interface is followed by a U+003A (:) and an identifier, then that identifier identifies the inherited interface.
fn check_inheritance_exists(interfaces : Array[Interface]) -> Unit raise {
  assert_true(
    interfaces.every(interface => {
      match interface.inheritance {
        Some(interface_name) => {
          let interface_name = strip_underscore(interface_name)

          interfaces.search_by(i => name_of_interface(i) == interface_name)
          is Some(_)
        }
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
      Some(interface_name) => {
        let interface_name = strip_underscore(interface_name)

        let inherited_interface_index = interfaces
          .search_by(i => name_of_interface(i) == interface_name)
          .unwrap()

        let inherited_interface = interfaces[inherited_interface_index]

        visit_interface(inherited_interface)
      }
      None => ()
    }

    visiting.remove(name)
    visited.add(name)
  }

  for interface in interfaces {
    visit_interface(interface)
  }
}
