///|
test "LegacyUnforgeable requires a regular attribute" {
  for
    (prefix, suffix, forms) in [
      (
        "[Exposed=*] interface A {",
        "};",
        [
          ("attribute", true),
          ("readonly attribute", true),
          ("static attribute", false),
          ("static readonly attribute", false),
          ("stringifier attribute", true),
          ("stringifier readonly attribute", true),
        ],
      ),
      (
        "[Exposed=*] interface A {}; partial interface A {",
        "};",
        [
          ("attribute", true),
          ("readonly attribute", true),
          ("static attribute", false),
          ("static readonly attribute", false),
          ("stringifier attribute", true),
          ("stringifier readonly attribute", true),
        ],
      ),
      (
        "interface mixin M {",
        "};",
        [
          ("attribute", true),
          ("readonly attribute", true),
          ("stringifier attribute", true),
          ("stringifier readonly attribute", true),
        ],
      ),
      (
        "interface mixin M {}; partial interface mixin M {",
        "};",
        [
          ("attribute", true),
          ("readonly attribute", true),
          ("stringifier attribute", true),
          ("stringifier readonly attribute", true),
        ],
      ),
      ("namespace N {", "};", [("readonly attribute", false)]),
      (
        "namespace N {}; partial namespace N {",
        "};",
        [("readonly attribute", false)],
      ),
    ] {
    for (form, expected) in forms {
      let declaration = prefix +
        " [LegacyUnforgeable] " +
        form +
        " long value; " +
        suffix
      assert_eq(check_source(declaration), expected)
    }
  }
  assert_true(
    check_source(
      "[Exposed=*] interface P { readonly attribute long value; }; [Exposed=*] interface A : P { [LegacyUnforgeable] inherit attribute long value; };",
    ),
  )
}

///|
test "LegacyUnforgeable rejects static operations" {
  assert_true(
    check_source(
      "[Exposed=*] interface A { [LegacyUnforgeable] undefined run(); };",
    ),
  )
  assert_false(
    check_source(
      "[Exposed=*] interface A { [LegacyUnforgeable] static undefined run(); };",
    ),
  )
}

///|
test "LegacyUnforgeable must appear on all operations with the same identifier" {
  assert_true(
    check_source(
      "[Exposed=*] interface A { [LegacyUnforgeable] undefined run(long value); [LegacyUnforgeable] undefined run(DOMString value); };",
    ),
  )
  assert_false(
    check_source(
      "[Exposed=*] interface A { [LegacyUnforgeable] undefined run(long value); undefined run(DOMString value); };",
    ),
  )
  assert_false(
    check_source(
      "[Exposed=*] interface A { undefined run(); }; partial interface A { [LegacyUnforgeable] undefined run(long value); };",
    ),
  )
  assert_false(
    check_source(
      "[Exposed=*] interface A { [LegacyUnforgeable] undefined run(); }; interface mixin M { undefined run(long value); }; A includes M;",
    ),
  )
}

///|
test "LegacyUnforgeable prevents same named members on derived interfaces" {
  let ancestor_attribute = "[Exposed=*] interface A { [LegacyUnforgeable] readonly attribute DOMString x; }; "
  for declaration in ["undefined x();", "readonly attribute long x;"] {
    assert_false(
      check_source(
        ancestor_attribute +
        "[Exposed=*] interface B : A { " +
        declaration +
        " };",
      ),
    )
  }
  assert_true(
    check_source(
      ancestor_attribute +
      "[Exposed=*] interface B : A { static undefined x(); };",
    ),
  )
  assert_true(
    check_source(ancestor_attribute + "[Exposed=*] interface B : A {};"),
  )
  assert_false(
    check_source(
      ancestor_attribute +
      "[Exposed=*] interface B : A {}; [Exposed=*] interface C : B { undefined x(); };",
    ),
  )
  assert_false(
    check_source(
      ancestor_attribute +
      "[Exposed=*] interface B : A {}; interface mixin M { undefined x(); }; B includes M;",
    ),
  )
  assert_false(
    check_source(
      ancestor_attribute +
      "[Exposed=*] interface B : A {}; partial interface B { undefined x(); };",
    ),
  )
  assert_false(
    check_source(
      "[Exposed=*] interface A { [LegacyUnforgeable] undefined x(); }; [Exposed=*] interface B : A { readonly attribute long x; };",
    ),
  )
}

///|
test "LegacyUnforgeable only recognizes the no arguments form" {
  for
    attribute in [
      "LegacyUnforgeable=value", "LegacyUnforgeable()", "LegacyUnforgeable=(value)",
    ] {
    assert_true(
      check_source(
        "[Exposed=*] interface A { [" +
        attribute +
        "] static undefined run(); };",
      ),
    )
  }
}
