///|
fn name(definition : Definition) -> StringView raise {
  match definition {
    Callback({ identifier: name, .. })
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
    | Typedef({ identifier: name, .. }) => name
    IncludesStatement(_) => fail("no name found")
  }
}


