///|
test "Promise attributes must be read only across all declaration parts" {
  for
    (prefix, suffix, forms) in [
      (
        "[Exposed=*] interface A {",
        "};",
        [
          ("attribute", false),
          ("readonly attribute", true),
          ("static attribute", false),
          ("static readonly attribute", true),
          ("inherit attribute", false),
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
          ("static readonly attribute", true),
          ("inherit attribute", false),
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
      ("namespace N {", "};", [("readonly attribute", true)]),
      (
        "namespace N {}; partial namespace N {",
        "};",
        [("readonly attribute", true)],
      ),
    ] {
    for (form, expected) in forms {
      for type_ in ["Promise<long>", "Pending", "_Pending"] {
        let declaration = prefix + form + " " + type_ + " value;" + suffix
        let definitions = "typedef Promise<long> _Pending;"
        assert_eq(check_source(definitions + declaration), expected)
        assert_eq(check_source(declaration + definitions), expected)
      }
    }
  }
}

///|
test "Promise attributes reject the four prohibited extended attributes" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A {", "};"),
      ("[Exposed=*] interface A { static readonly attribute long first;", "};"),
      ("[Exposed=*] interface A {}; partial interface A {", "};"),
      ("interface mixin M {", "};"),
      ("interface mixin M {}; partial interface mixin M {", "};"),
      ("namespace N {", "};"),
      ("namespace N {}; partial namespace N {", "};"),
    ] {
    for type_ in ["Promise<long>", "Pending"] {
      for
        attr in [
          "LegacyLenientSetter", "PutForwards=value", "Replaceable", "SameObject",
          "Example, SameObject", "SameObject, Example",
        ] {
        assert_false(
          check_source(
            "typedef Promise<long> Pending;" +
            prefix +
            "[" +
            attr +
            "] readonly attribute " +
            type_ +
            " value;" +
            suffix,
          ),
        )
      }
    }
  }
  for form in ["static readonly attribute", "stringifier readonly attribute"] {
    for
      attr in [
        "LegacyLenientSetter", "PutForwards=value", "Replaceable", "SameObject",
      ] {
      assert_false(
        check_source(
          "[Exposed=*] interface A { [" +
          attr +
          "] " +
          form +
          " Promise<long> value; };",
        ),
      )
    }
  }
}

///|
test "Promise checks only recognize the permitted extended attribute forms" {
  for
    attr in [
      "LegacyLenientSetter=value", "Replaceable=value", "SameObject=value", "PutForwards",
      "PutForwards=(value)", "Example",
    ] {
    assert_true(
      check_source(
        "[Exposed=*] interface A { [" +
        attr +
        "] readonly attribute Promise<long> value; };",
      ),
    )
  }
  for
    source in [
      "typedef Promise<long> Pending;", "[Exposed=*] interface A { Promise<long> run(); };",
      "[Exposed=*] interface A { attribute long value; readonly attribute Promise<long> pending; };",
      "typedef (Value or DOMString) Value; [Exposed=*] interface A { attribute Value value; };",
      "typedef Promise<Value> Value; [Exposed=*] interface A { readonly attribute Value value; };",
    ] {
    assert_true(check_source(source))
  }
}
