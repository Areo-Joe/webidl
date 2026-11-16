///|
test "LegacyLenientThis cannot be used on static or namespace attributes" {
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
        " [LegacyLenientThis] " +
        form +
        " long value; " +
        suffix
      assert_eq(check_attribute_source(declaration), expected)
    }
  }
  assert_true(
    check_attribute_source(
      "[Exposed=*] interface P { readonly attribute long value; }; [Exposed=*] interface A : P { [LegacyLenientThis] inherit attribute long value; };",
    ),
  )
}

///|
test "LegacyLenientThis only recognizes the no arguments form" {
  for
    attribute in [
      "LegacyLenientThis=value", "LegacyLenientThis()", "LegacyLenientThis=(value)",
    ] {
    assert_true(
      check_attribute_source(
        "[Exposed=*] interface A { [" +
        attribute +
        "] static attribute long value; };",
      ),
    )
  }
}
