///|
test "Replaceable requires a read only regular attribute" {
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
        " [Replaceable] " +
        form +
        " long value; " +
        suffix
      assert_eq(check_source(declaration), expected)
    }
  }
  assert_false(
    check_source(
      "[Exposed=*] interface P { readonly attribute long value; }; [Exposed=*] interface A : P { [Replaceable] inherit attribute long value; };",
    ),
  )
}

///|
test "Replaceable cannot combine with LegacyLenientSetter or PutForwards" {
  let target = "[Exposed=*] interface T { attribute long value; }; "
  for
    attribute in [
      "[Replaceable, LegacyLenientSetter]", "[LegacyLenientSetter, Replaceable]",
      "[Replaceable, PutForwards=value]", "[PutForwards=value, Replaceable]",
    ] {
    assert_false(
      check_source(
        target +
        "[Exposed=*] interface A { " +
        attribute +
        " readonly attribute T value; };",
      ),
    )
  }
  assert_true(
    check_source(
      target +
      "[Exposed=*] interface A { [Replaceable] readonly attribute T value; };",
    ),
  )
}

///|
test "Replaceable only recognizes the no arguments form" {
  for attribute in ["Replaceable=value", "Replaceable()", "Replaceable=(value)"] {
    assert_true(
      check_source(
        "[Exposed=*] interface A { [" + attribute + "] attribute long value; };",
      ),
    )
  }
}
