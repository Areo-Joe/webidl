///|
test "LegacyLenientSetter requires a read only regular attribute" {
  for
    (prefix, suffix, forms) in [
      (
        "[Exposed=*] interface A {",
        "};",
        [
          ("attribute", false),
          ("readonly attribute", true),
          ("static attribute", false),
          ("static readonly attribute", false),
          ("stringifier attribute", false),
          ("stringifier readonly attribute", true),
        ],
      ),
      (
        "[Exposed=*] interface A {}; partial interface A {",
        "};",
        [
          ("attribute", false),
          ("readonly attribute", true),
          ("static attribute", false),
          ("static readonly attribute", false),
          ("stringifier attribute", false),
          ("stringifier readonly attribute", true),
        ],
      ),
      (
        "interface mixin M {",
        "};",
        [
          ("attribute", false),
          ("readonly attribute", true),
          ("stringifier attribute", false),
          ("stringifier readonly attribute", true),
        ],
      ),
      (
        "interface mixin M {}; partial interface mixin M {",
        "};",
        [
          ("attribute", false),
          ("readonly attribute", true),
          ("stringifier attribute", false),
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
        " [LegacyLenientSetter] " +
        form +
        " long value; " +
        suffix
      assert_eq(check_source(declaration), expected)
    }
  }
  assert_false(
    check_source(
      "[Exposed=*] interface P { readonly attribute long value; }; [Exposed=*] interface A : P { [LegacyLenientSetter] inherit attribute long value; };",
    ),
  )
}

///|
test "LegacyLenientSetter cannot combine with PutForwards or Replaceable" {
  let prefix = "[Exposed=*] interface T { attribute long value; }; [Exposed=*] interface A { "
  for
    attributes in [
      "[LegacyLenientSetter, PutForwards=value]", "[PutForwards=value, LegacyLenientSetter]",
      "[LegacyLenientSetter, Replaceable]", "[Replaceable, LegacyLenientSetter]",
    ] {
    assert_false(
      check_source(prefix + attributes + " readonly attribute T value; };"),
    )
  }
  for
    attributes in [
      "[LegacyLenientSetter]", "[PutForwards=value]", "[Replaceable]",
    ] {
    assert_true(
      check_source(prefix + attributes + " readonly attribute T value; };"),
    )
  }
}

///|
test "LegacyLenientSetter only recognizes the no arguments form" {
  for
    attribute in [
      "LegacyLenientSetter=value", "LegacyLenientSetter()", "LegacyLenientSetter=(value)",
    ] {
    assert_true(
      check_source(
        "[Exposed=*] interface A { [" + attribute + "] attribute long value; };",
      ),
    )
  }
}
