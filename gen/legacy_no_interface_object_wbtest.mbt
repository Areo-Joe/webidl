///|
fn check_legacy_no_interface_object_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "LegacyNoInterfaceObject recognizes only the no-arguments form" {
  for
    (source, expected) in [
      ("[LegacyNoInterfaceObject]", true),
      ("[LegacyNoInterfaceObject()]", false),
      ("[LegacyNoInterfaceObject=Name]", false),
      ("[LegacyNoInterfaceObject=(First,Second)]", false),
      ("[LegacyNoInterfaceObject=Name()]", false),
      ("[LegacyNoInterfaceObject=*]", false),
      ("[LegacyNoInterfaceObject=\"Name\"]", false),
      ("[LegacyNoInterfaceObject=1]", false),
      ("[LegacyNoInterfaceObject=1.5]", false),
      ("[LegacyNoInterfaceObject=(1,2)]", false),
      ("[Other]", false),
      ("[legacyNoInterfaceObject]", false),
    ] {
    let (attrs, rest) = @parser.ExtendedAttributeList::parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    assert_eq(attrs.iter().count(), 1)
    assert_eq(attrs.iter().any(is_valid_legacy_no_interface_object), expected)
  }
}

///|
test "LegacyNoInterfaceObject forbids constructors and static operations on the interface" {
  for
    (members, expected) in [
      ("", true),
      ("constructor();", false),
      ("constructor(long value);", false),
      ("static undefined run();", false),
      ("static long value(DOMString key);", false),
      ("static attribute long value;", true),
      ("static readonly attribute long value;", true),
      ("undefined run();", true),
      ("const long VALUE = 1; attribute long value;", true),
      ("getter DOMString (DOMString key);", true),
    ] {
    assert_eq(
      check_legacy_no_interface_object_source(
        "[Exposed=*, LegacyNoInterfaceObject] interface A { " + members + " };",
      ),
      expected,
    )
  }
  assert_true(
    check_legacy_no_interface_object_source(
      "[Exposed=*] interface A { constructor(); static undefined run(); };",
    ),
  )
}

///|
test "LegacyNoInterfaceObject checks static operations in every partial regardless of order" {
  for
    source in [
      "[Exposed=*, LegacyNoInterfaceObject] interface A {}; partial interface A { static undefined run(); };",
      "partial interface A { static undefined run(); }; [Exposed=*, LegacyNoInterfaceObject] interface A {};",
      "partial interface A { undefined run(); }; [Exposed=*, LegacyNoInterfaceObject] interface A {}; partial interface A { static undefined last(); };",
    ] {
    assert_false(check_legacy_no_interface_object_source(source))
  }
  assert_true(
    check_legacy_no_interface_object_source(
      "[Exposed=*, LegacyNoInterfaceObject] interface A {}; partial interface A { static attribute long value; undefined run(); };",
    ),
  )
  assert_true(
    check_legacy_no_interface_object_source(
      "[Exposed=*] interface A {}; partial interface A { static undefined run(); };",
    ),
  )
}

///|
test "LegacyNoInterfaceObject inheritance requires the attribute on derived interfaces" {
  for
    (source, expected) in [
      (
        "[Exposed=*, LegacyNoInterfaceObject] interface A {}; [Exposed=*] interface B : A {};",
        false,
      ),
      (
        "[Exposed=*, LegacyNoInterfaceObject] interface A {}; [Exposed=*, LegacyNoInterfaceObject] interface B : A {};",
        true,
      ),
      (
        "[Exposed=*, LegacyNoInterfaceObject] interface A {}; [Exposed=*, LegacyNoInterfaceObject] interface B : A {}; [Exposed=*] interface C : B {};",
        false,
      ),
      (
        "[Exposed=*, LegacyNoInterfaceObject] interface A {}; [Exposed=*, LegacyNoInterfaceObject] interface B : A {}; [Exposed=*, LegacyNoInterfaceObject] interface C : B {};",
        true,
      ),
      (
        "[Exposed=*] interface A {}; [Exposed=*, LegacyNoInterfaceObject] interface B : A {};",
        true,
      ),
      ("[Exposed=*] interface A {}; [Exposed=*] interface B : A {};", true),
      (
        "[Exposed=*] interface B : _A {}; [Exposed=*, LegacyNoInterfaceObject] interface A {};",
        false,
      ),
      (
        "[Exposed=*] interface A { constructor(); static undefined run(); }; [Exposed=*, LegacyNoInterfaceObject] interface B : A {};",
        true,
      ),
      (
        "[Exposed=*] interface A {}; partial interface A { static undefined run(); }; [Exposed=*, LegacyNoInterfaceObject] interface B : A {};",
        true,
      ),
    ] {
    assert_eq(check_legacy_no_interface_object_source(source), expected)
  }
}

///|
test "LegacyNoInterfaceObject leaves malformed forms and unsupported placements for later validation" {
  for
    source in [
      "[Exposed=*, LegacyNoInterfaceObject()] interface A { constructor(); static undefined run(); };",
      "[Exposed=*, LegacyNoInterfaceObject=Name] interface A { constructor(); static undefined run(); };",
      "[Exposed=*, LegacyNoInterfaceObject()] interface A {}; [Exposed=*] interface B : A {};",
      "[Exposed=*] interface A {}; [LegacyNoInterfaceObject] partial interface A { static undefined run(); };",
    ] {
    assert_true(check_legacy_no_interface_object_source(source))
  }
  assert_false(
    check_legacy_no_interface_object_source(
      "[Exposed=*, LegacyNoInterfaceObject] interface A {}; [Exposed=*, LegacyNoInterfaceObject()] interface B : A {};",
    ),
  )
}
