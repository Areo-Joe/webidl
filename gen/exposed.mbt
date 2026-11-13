///|
enum Exposed {
  Ident(StringView)
  IdentList(Array[StringView])
  Wildcard
}

///|
/// The own exposure set is either a set of identifiers or the special value *, defined as follows:
/// 
/// If the [Exposed] extended attribute takes an identifier I
/// The own exposure set is the set « I ».
/// 
/// If the [Exposed] extended attribute takes an identifier list I
/// The own exposure set is the set I.
/// 
/// If the [Exposed] extended attribute takes a wildcard
/// The own exposure set is *.
fn Exposed::own_exposure_set(self : Self) -> ExposureSet {
  match self {
    Ident(x) => List(Set([strip_underscore(x)]))
    IdentList(x) => List(Set(x.map(strip_underscore)))
    Wildcard => All
  }
}

///|
/// When the [Exposed] extended attribute appears on an interface, partial interface, interface mixin, partial interface mixin, callback interface, namespace, partial namespace, or an individual interface member, interface mixin member, or namespace member, it indicates that the construct is exposed on that particular set of global interfaces.
enum ExposedAble {
  Interface(Interface)
  PartialInterface(PartialInterface)
  InterfaceMixin(InterfaceMixin)
  PartialInterfaceMixin(PartialInterfaceMixin)
  CallbackInterface(CallbackInterface)
  Namespace(Namespace)
  PartialNamespace(PartialNamespace)
  InterfaceMember(InterfaceMember)
  PartialInterfaceMember(PartialInterfaceMember)
  InterfaceMixinMember(InterfaceMixinMember)
  PartialInterfaceMixinMember(PartialInterfaceMixinMember)
  NamespaceMember(NamespaceMember)
  PartialNamespaceMember(PartialNamespaceMember)
}

///|
fn ExposedAble::exposed_attribute(self : Self) -> Exposed? {
  let extended_attribute_list = match self {
    Interface(x) => x.extended_attribute_list
    PartialInterface(x) => x.extended_attribute_list
    InterfaceMixin(x) => x.extended_attribute_list
    PartialInterfaceMixin(x) => x.extended_attribute_list
    CallbackInterface(x) => x.extended_attribute_list
    Namespace(x) => x.extended_attribute_list
    PartialNamespace(x) => x.extended_attribute_list
    InterfaceMember(x) => x.extended_attribute_list
    PartialInterfaceMember(x) => x.extended_attribute_list
    InterfaceMixinMember(x) => x.extended_attribute_list
    PartialInterfaceMixinMember(x) => x.extended_attribute_list
    NamespaceMember(x) => x.extended_attribute_list
    PartialNamespaceMember(x) => x.extended_attribute_list
  }

  for attr in extended_attribute_list.iter() {
    if is_valid_exposed(attr) is Some(exposed) {
      return Some(exposed)
    }
  }

  None
}

///|
enum ExposureSet {
  List(Set[StringView])
  All
}

///|
fn ExposureSet::empty() -> Self {
  List(Set([]))
}

///|
fn ExposureSet::is_subset(self : Self, other : Self) -> Bool {
  match (self, other) {
    (_, All) => true
    (All, _) => false
    (List(self_set), List(other_set)) => self_set.is_subset(other_set)
  }
}

///|
/// The [Exposed] extended attribute must either take an identifier, take an identifier list or take a wildcard. 
fn is_valid_exposed(attr : @parser.ExtendedAttribute) -> Exposed? {
  match attr {
    Ident({ identifier: "Exposed", value, }) => Some(Ident(value))
    IdentList({ identifier: "Exposed", identifier_list, }) =>
      Some(IdentList(identifier_list.iter().collect()))
    Wildcard({ identifier: "Exposed", }) => Some(Wildcard)
    _ => None
  }
}

///|
/// Each of the identifiers mentioned must be a global name of some interface and be unique.
fn exposed_unique_identifier_match_interface_global_name(
  exposed : Exposed,
  global_names : Array[StringView],
) -> Unit raise {
  match exposed {
    Ident(name) => assert_true(global_names.contains(strip_underscore(name)))
    IdentList(names) => {
      let names = names.map(strip_underscore)

      let dedup = Set(names)
      assert_eq(dedup.length(), names.length())

      assert_true(names.every(name => global_names.contains(name)))
    }
    Wildcard => ()
  }
}

///|
/// If [Exposed] appears on an interface or namespace member, then the member’s exposure set must be a subset of the exposure set of the interface or namespace it is a member of.
fn check_exposed_interface_member_is_subset_of_interface(
  interface : Interface,
) -> Unit raise {
  for
    interface_member in interface.members.filter(x => {
      x.extended_attribute_list.iter().any(x => is_valid_exposed(x) is Some(_))
    }) {
    assert_true(
      exposure_set(ExposedSetStruct::InterfaceMember(interface_member), None).is_subset(
        exposure_set(ExposedSetStruct::Interface(interface), None),
      ),
    )
  }
}

///|
/// If an interface X inherits from another interface Y then the exposure set of X must be a subset of the exposure set of Y.
fn check_exposed_interface_is_subset_of_inheritance(
  interface : Interface,
) -> Unit raise {
  match interface.inheritance {
    Some(inheritance) =>
      assert_true(
        exposure_set(ExposedSetStruct::Interface(interface), None).is_subset(
          exposure_set(ExposedSetStruct::Interface(inheritance), None),
        ),
      )
    None => ()
  }
}

///|
/// C is an interface, callback interface, namespace, interface member, interface mixin member, or namespace member.
enum ExposedSetStruct {
  Interface(Interface)
  CallbackInterface(CallbackInterface)
  Namespace(Namespace)
  InterfaceMember(InterfaceMember)
  PartialInterfaceMember(PartialInterfaceMember)
  InterfaceMixinMember(InterfaceMixinMember)
  PartialInterfaceMixinMember(PartialInterfaceMixinMember)
  NamespaceMember(NamespaceMember)
  PartialNamespaceMember(PartialNamespaceMember)
}

///|
fn ExposedSetStruct::to_exposed_able(self : Self) -> ExposedAble {
  match self {
    Interface(x) => Interface(x)
    CallbackInterface(x) => CallbackInterface(x)
    Namespace(x) => Namespace(x)
    InterfaceMember(x) => InterfaceMember(x)
    PartialInterfaceMember(x) => PartialInterfaceMember(x)
    InterfaceMixinMember(x) => InterfaceMixinMember(x)
    PartialInterfaceMixinMember(x) => PartialInterfaceMixinMember(x)
    NamespaceMember(x) => NamespaceMember(x)
    PartialNamespaceMember(x) => PartialNamespaceMember(x)
  }
}

///|
/// C is an interface member, interface mixin member, namespace member, partial interface, partial interface mixin, partial namespace, or interface mixin.
enum ExposeureSetIntersectionStruct {
  InterfaceMember(InterfaceMember)
  PartialInterfaceMember(PartialInterfaceMember)
  InterfaceMixinMember(InterfaceMixinMember)
  PartialInterfaceMixinMember(PartialInterfaceMixinMember)
  NamespaceMember(NamespaceMember)
  PartialNamespaceMember(PartialNamespaceMember)
  PartialInterface(PartialInterface)
  PartialInterfaceMixin(PartialInterfaceMixin)
  PartialNamespace(PartialNamespace)
  InterfaceMixin(InterfaceMixin)
}

///|
fn ExposeureSetIntersectionStruct::to_exposed_able(self : Self) -> ExposedAble {
  match self {
    InterfaceMember(x) => InterfaceMember(x)
    PartialInterfaceMember(x) => PartialInterfaceMember(x)
    InterfaceMixinMember(x) => InterfaceMixinMember(x)
    PartialInterfaceMixinMember(x) => PartialInterfaceMixinMember(x)
    NamespaceMember(x) => NamespaceMember(x)
    PartialNamespaceMember(x) => PartialNamespaceMember(x)
    PartialInterface(x) => PartialInterface(x)
    PartialInterfaceMixin(x) => PartialInterfaceMixin(x)
    PartialNamespace(x) => PartialNamespace(x)
    InterfaceMixin(x) => InterfaceMixin(x)
  }
}

///|
fn ExposeureSetIntersectionStruct::own_exposure_set(self : Self) -> ExposureSet {
  match self.to_exposed_able().exposed_attribute() {
    Some(x) => x.own_exposure_set()
    None => ExposureSet::empty()
  }
}

///|
enum ExposureSetFinal {
  Interface(Interface)
  CallbackInterface(CallbackInterface)
  Namespace(Namespace)
}

///|
fn ExposureSetFinal::extended_attribute_list(
  self : Self,
) -> @parser.ExtendedAttributeList {
  match self {
    CallbackInterface(x) => x.extended_attribute_list
    Interface(x) => x.extended_attribute_list
    Namespace(x) => x.extended_attribute_list
  }
}

///|
fn ExposureSetFinal::to_exposed_able(self : Self) -> ExposedAble {
  match self {
    CallbackInterface(x) => CallbackInterface(x)
    Interface(x) => Interface(x)
    Namespace(x) => Namespace(x)
  }
}

///|
fn ExposureSetFinal::own_exposure_set(self : Self) -> ExposureSet {
  match self.to_exposed_able().exposed_attribute() {
    Some(x) => x.own_exposure_set()
    None => ExposureSet::empty()
  }
}

///|
/// exposure set of a construct C
/// Assert: C is an interface, callback interface, namespace, interface member, interface mixin member, or namespace member.
fn exposure_set(c : ExposedSetStruct, host : Interface?) -> ExposureSet raise {

  // Let H be C’s host interface if C is an interface mixin member, or null otherwise.
  let h = match c {
    InterfaceMixinMember(_) | PartialInterfaceMixinMember(_) =>
      Some(host.unwrap())
    _ => None
  }

  // If C is an interface member, interface mixin member, or namespace member, then:
  let c = match c {
    InterfaceMember(interface_member) =>
      if c.to_exposed_able().exposed_attribute() is Some(_) {
        // If the [Exposed] extended attribute is specified on C, return the exposure set intersection of C and H.

        return exposure_set_intersection(
          ExposeureSetIntersectionStruct::InterfaceMember(interface_member),
          h,
        )
      } else {
        ExposureSetFinal::Interface(interface_member.host)
      }
    PartialInterfaceMember(partial_interface_member) =>
      if c.to_exposed_able().exposed_attribute() is Some(_) {
        // If the [Exposed] extended attribute is specified on C, return the exposure set intersection of C and H.

        return exposure_set_intersection(
          ExposeureSetIntersectionStruct::PartialInterfaceMember(
            partial_interface_member,
          ),
          h,
        )
      } else {
        // If C is a partial interface, partial interface mixin, or partial namespace, then:
        let c = partial_interface_member.host
        if c.extended_attribute_list
          .iter()
          .any(x => is_valid_exposed(x) is Some(_)) {
          // If the [Exposed] extended attribute is specified on C, return the exposure set intersection of C and H.
          return exposure_set_intersection(
            ExposeureSetIntersectionStruct::PartialInterface(c),
            h,
          )
        } else {
          // Set C to the original interface, interface mixin, or namespace definition of C.
          ExposureSetFinal::Interface(c.host)
        }
      }
    InterfaceMixinMember(interface_mixin_member) =>
      if c.to_exposed_able().exposed_attribute() is Some(_) {
        // If the [Exposed] extended attribute is specified on C, return the exposure set intersection of C and H.

        return exposure_set_intersection(
          ExposeureSetIntersectionStruct::InterfaceMixinMember(
            interface_mixin_member,
          ),
          h,
        )
      } else {
        // Set C to the original interface, interface mixin, or namespace definition of C.

        let c = interface_mixin_member.host

        // If C is an interface mixin, then:
        // Assert: H is not null.

        let h = h.unwrap()

        if c.extended_attribute_list
          .iter()
          .any(x => is_valid_exposed(x) is Some(_)) {
          // If the [Exposed] extended attribute is specified on C, return the exposure set intersection of C and H.

          return exposure_set_intersection(
            ExposeureSetIntersectionStruct::InterfaceMixin(c),
            Some(h),
          )
        } else {
          // Set C to H.
          ExposureSetFinal::Interface(h)
        }
      }
    PartialInterfaceMixinMember(partial_interface_mixin_member) =>
      if c.to_exposed_able().exposed_attribute() is Some(_) {
        // If the [Exposed] extended attribute is specified on C, return the exposure set intersection of C and H.

        return exposure_set_intersection(
          ExposeureSetIntersectionStruct::PartialInterfaceMixinMember(
            partial_interface_mixin_member,
          ),
          h,
        )
      } else {
        let c = partial_interface_mixin_member.host

        // If C is a partial interface, partial interface mixin, or partial namespace, then:

        if c.extended_attribute_list
          .iter()
          .any(x => is_valid_exposed(x) is Some(_)) {
          // If the [Exposed] extended attribute is specified on C, return the exposure set intersection of C and H.

          return exposure_set_intersection(
            ExposeureSetIntersectionStruct::PartialInterfaceMixin(c),
            h,
          )
        } else {
          // Set C to the original interface, interface mixin, or namespace definition of C.

          let c = c.host

          // If C is an interface mixin, then:
          // Assert: H is not null.

          let h = h.unwrap()

          if c.extended_attribute_list
            .iter()
            .any(x => is_valid_exposed(x) is Some(_)) {
            // If the [Exposed] extended attribute is specified on C, return the exposure set intersection of C and H.

            return exposure_set_intersection(
              ExposeureSetIntersectionStruct::InterfaceMixin(c),
              Some(h),
            )
          } else {
            // Set C to H.
            ExposureSetFinal::Interface(h)
          }
        }
      }
    NamespaceMember(namespace_member) =>
      if c.to_exposed_able().exposed_attribute() is Some(_) {
        // If the [Exposed] extended attribute is specified on C, return the exposure set intersection of C and H.

        return exposure_set_intersection(
          ExposeureSetIntersectionStruct::NamespaceMember(namespace_member),
          h,
        )
      } else {
        ExposureSetFinal::Namespace(namespace_member.host)
      }
    PartialNamespaceMember(partial_namespace_member) =>
      if c.to_exposed_able().exposed_attribute() is Some(_) {
        // If the [Exposed] extended attribute is specified on C, return the exposure set intersection of C and H.

        return exposure_set_intersection(
          ExposeureSetIntersectionStruct::PartialNamespaceMember(
            partial_namespace_member,
          ),
          h,
        )
      } else {
        // Set C to the interface, partial interface, interface mixin, partial interface mixin, namespace, or partial namespace C is declared on.
        let c = partial_namespace_member.host

        // If C is a partial interface, partial interface mixin, or partial namespace, then:

        if c.extended_attribute_list
          .iter()
          .any(x => is_valid_exposed(x) is Some(_)) {
          // If the [Exposed] extended attribute is specified on C, return the exposure set intersection of C and H.

          return exposure_set_intersection(
            ExposeureSetIntersectionStruct::PartialNamespace(c),
            h,
          )
        } else {
          // Set C to the original interface, interface mixin, or namespace definition of C.

          let c = c.host
          assert_true(
            c.extended_attribute_list
            .iter()
            .any(x => is_valid_exposed(x) is Some(_)),
          )

          return ExposedAble::Namespace(c)
            .exposed_attribute()
            .unwrap()
            .own_exposure_set()
        }
      }
    Interface(x) => ExposureSetFinal::Interface(x)
    CallbackInterface(x) => ExposureSetFinal::CallbackInterface(x)
    Namespace(x) => ExposureSetFinal::Namespace(x)
  }

  c.own_exposure_set()
}

///|
/// The exposure set intersection of a construct C and interface-or-null H 
/// Assert: C is an interface member, interface mixin member, namespace member, partial interface, partial interface mixin, partial namespace, or interface mixin.
/// Assert: H is an interface or null.
fn exposure_set_intersection(
  c : ExposeureSetIntersectionStruct,
  h : Interface?,
) -> ExposureSet raise {
  // If H is null, return C’s own exposure set.
  guard h is Some(interface) else { c.own_exposure_set() }

  // If C’s own exposure set is *, return H’s exposure set.
  guard c.own_exposure_set() is List(c_list) else {
    exposure_set(ExposedSetStruct::Interface(interface), None)
  }

  let h_exposure_set = exposure_set(
    ExposedSetStruct::Interface(interface),
    None,
  )

  match h_exposure_set {
    // If H’s exposure set is *, return C’s own exposure set.
    All => c.own_exposure_set()
    // Return the intersection of C’s own exposure set and H’s exposure set.
    List(h_list) => List(h_list.intersection(c_list))
  }
}
