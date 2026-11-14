///|
fn check_legacy_window_alias_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "LegacyWindowAlias recognizes identifier and identifier-list forms" {
  let (attrs, rest) = @parser.ExtendedAttributeList::parse(
    @lexer.tokenize(
      "[LegacyWindowAlias=_First, LegacyWindowAlias=(_First,Second)]",
    ).exact_view(),
  )
  assert_true(rest is [])
  let recognized = attrs
    .iter()
    .filter_map(is_valid_legacy_window_alias)
    .collect()
  assert_eq(recognized.length(), 2)
  assert_true(recognized[0] is Ident("_First"))
  guard recognized[1] is IdentList(names) else {
    fail("expected identifier list")
  }
  assert_eq(names, ["_First", "Second"])
  assert_eq(legacy_window_alias_names(attrs), ["First", "First", "Second"])
}

///|
test "LegacyWindowAlias allows one attribute and requires distinct normalized names" {
  for
    (attributes, expected) in [
      ("LegacyWindowAlias=Old", true),
      ("LegacyWindowAlias=(Old,Other)", true),
      ("LegacyWindowAlias=(Old,Old)", false),
      ("LegacyWindowAlias=(Old,_Old)", false),
      ("LegacyWindowAlias=Old, LegacyWindowAlias=Other", false),
      ("LegacyWindowAlias=Old, LegacyWindowAlias=(Other,Third)", false),
      ("LegacyWindowAlias=Old, LegacyWindowAlias()", true),
      ("LegacyWindowAlias(), LegacyWindowAlias=Old", true),
    ] {
    assert_eq(
      check_legacy_window_alias_source(
        "[Exposed=*, " + attributes + "] interface A {};",
      ),
      expected,
    )
  }
}

///|
test "LegacyWindowAlias names cannot be reserved or belong to another alias" {
  for
    (name, expected) in [
      ("_constructor", false),
      ("toString", false),
      ("_toString", false),
      ("Old", true),
      ("_Old", true),
      ("prototype", true),
    ] {
    assert_eq(
      check_legacy_window_alias_source(
        "[Exposed=*, LegacyWindowAlias=" + name + "] interface A {};",
      ),
      expected,
    )
  }
  for
    source in [
      "[Exposed=*, LegacyWindowAlias=Old] interface A {}; [Exposed=*, LegacyWindowAlias=_Old] interface B {};",
      "[Exposed=*, LegacyWindowAlias=(First,Old)] interface B {}; [Exposed=*, LegacyWindowAlias=_Old] interface A {};",
    ] {
    assert_false(check_legacy_window_alias_source(source))
  }
  assert_true(
    check_legacy_window_alias_source(
      "[Exposed=*, LegacyWindowAlias=First] interface A {}; [Exposed=*, LegacyWindowAlias=Second] interface B {};",
    ),
  )
}

///|
test "LegacyWindowAlias names cannot match factory names or interface object names" {
  for
    (source, expected) in [
      ("[Exposed=*, LegacyWindowAlias=_A] interface A {};", false),
      (
        "[Exposed=*] interface _Other {}; [Exposed=*, LegacyWindowAlias=Other] interface A {};",
        false,
      ),
      (
        "[Exposed=*, LegacyWindowAlias=_Other] interface A {}; [Exposed=*] interface Other {};",
        false,
      ),
      (
        "[Exposed=*, LegacyNoInterfaceObject] interface Other {}; [Exposed=*, LegacyWindowAlias=Other] interface A {};",
        true,
      ),
      (
        "[Exposed=*, LegacyNoInterfaceObject()] interface Other {}; [Exposed=*, LegacyWindowAlias=Other] interface A {};",
        false,
      ),
      (
        "namespace NS {}; [Exposed=*, LegacyNamespace=NS] interface Other {}; [Exposed=*, LegacyWindowAlias=Other] interface A {};",
        false,
      ),
      (
        "dictionary Other {}; [Exposed=*, LegacyWindowAlias=Other] interface A {};",
        true,
      ),
      (
        "[Exposed=*, LegacyWindowAlias=_Create, LegacyFactoryFunction=Create()] interface A {};",
        false,
      ),
      (
        "[Exposed=*, LegacyFactoryFunction=_Create()] interface B {}; [Exposed=*, LegacyWindowAlias=Create] interface A {};",
        false,
      ),
      (
        "[Exposed=*, LegacyWindowAlias=Create] interface A {}; [Exposed=*, LegacyFactoryFunction=_Create()] interface B {};",
        false,
      ),
    ] {
    assert_eq(check_legacy_window_alias_source(source), expected)
  }
}

///|
test "LegacyWindowAlias cannot share an interface with LegacyNoInterfaceObject or LegacyNamespace" {
  for
    (other, expected) in [
      ("LegacyNoInterfaceObject", false),
      ("LegacyNamespace=NS", false),
      ("LegacyNoInterfaceObject()", true),
      ("LegacyNoInterfaceObject=Name", true),
      ("LegacyNamespace", true),
      ("LegacyNamespace=NS()", true),
      ("LegacyNamespace=(NS,Other)", true),
    ] {
    for
      attrs in [
        "LegacyWindowAlias=Old, " + other,
        other + ", LegacyWindowAlias=Old",
      ] {
      assert_eq(
        check_legacy_window_alias_source(
          "namespace NS {}; [Exposed=*, " + attrs + "] interface A {};",
        ),
        expected,
      )
    }
  }
}

///|
test "LegacyWindowAlias requires Window in its interface exposure set" {
  let globals = "[Exposed=*, Global=Window] interface Window {}; [Exposed=*, Global=Worker] interface Worker {};"
  for
    (attrs, expected) in [
      ("Exposed=Window, LegacyWindowAlias=Old", true),
      ("Exposed=_Window, LegacyWindowAlias=Old", true),
      ("Exposed=(Window,Worker), LegacyWindowAlias=Old", true),
      ("Exposed=*, LegacyWindowAlias=Old", true),
      ("Exposed=Worker, LegacyWindowAlias=Old", false),
      ("LegacyWindowAlias=Old", false),
      ("Exposed=*, SecureContext, LegacyWindowAlias=Old", true),
      ("Exposed=*, CrossOriginIsolated, LegacyWindowAlias=Old", true),
      ("Exposed=Worker, LegacyWindowAlias()", true),
    ] {
    assert_eq(
      check_legacy_window_alias_source(
        globals + "[" + attrs + "] interface A {};",
      ),
      expected,
    )
  }
  assert_true(
    check_legacy_window_alias_source(
      globals +
      "[Exposed=*, LegacyWindowAlias=Old] interface Parent {}; [Exposed=Worker] interface Child : Parent {};",
    ),
  )
}

///|
test "LegacyWindowAlias leaves malformed forms and unsupported placements for later validation" {
  for
    source in [
      "[Exposed=*, LegacyWindowAlias()] interface A {};", "[Exposed=*, LegacyWindowAlias=Old()] interface A {};",
      "[Exposed=*, LegacyNoInterfaceObject, LegacyWindowAlias()] interface A {};",
      "[Exposed=*, LegacyNamespace=NS, LegacyWindowAlias()] interface A {};", "[Exposed=*] interface A {}; [LegacyWindowAlias=Old] partial interface A {};",
    ] {
    assert_true(check_legacy_window_alias_source(source))
  }
}

///|
test "LegacyWindowAlias leaves other forms and other attribute names unrecognized" {
  for
    source in [
      "[LegacyWindowAlias]", "[LegacyWindowAlias()]", "[LegacyWindowAlias=Name()]",
      "[LegacyWindowAlias=*]", "[LegacyWindowAlias=\"Name\"]", "[LegacyWindowAlias=1]",
      "[LegacyWindowAlias=1.5]", "[LegacyWindowAlias=(1,2)]", "[Other=Name]", "[legacyWindowAlias=Name]",
    ] {
    let (attrs, rest) = @parser.ExtendedAttributeList::parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    assert_eq(attrs.iter().count(), 1)
    assert_true(
      attrs.iter().all(attr => is_valid_legacy_window_alias(attr) is None),
    )
    assert_eq(legacy_window_alias_names(attrs), [])
  }
}
