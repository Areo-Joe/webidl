///|
enum Exposed {
  Ident(StringView)
  IdentList(Array[StringView])
  Wildcard
}

///|
/// The [Exposed] extended attribute must either take an identifier, take an identifier list or take a wildcard. 
fn is_valid_exposed(attr : @parser.ExtendedAttribute) -> Exposed? {
  match attr {
    Ident({ identifier: "Exposed", value }) => Some(Ident(value))
    IdentList({ identifier: "Exposed", identifier_list }) =>
      Some(IdentList(identifier_list.iter().collect()))
    Wildcard({ identifier: "Exposed" }) => Some(Wildcard)
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
struct WithExposed {
  body : WithExposedBody
  extended_attribute_list : @parser.ExtendedAttributeList
}

///|
enum WithExposedBody {
  Interface(Interface)
  CallbackInterface(CallbackInterface)
  Namespace(@parser.Namespace)
  InterfaceMember(@parser.InterfaceMember)
  InterfaceMinxinMember(@parser.MixinMember)
  NamespaceMember(@parser.NamespaceMember)
}

///|
fn exposed_set_of_interface(with_exposed : WithExposed) -> Unit {
  ...
}
