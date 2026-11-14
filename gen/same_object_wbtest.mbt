///|
test "SameObject requires read only attributes across declaration parts" {
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
      for type_ in ["object", "T", "Alias", "_Alias"] {
        let declaration = prefix +
          " [SameObject] " +
          form +
          " " +
          type_ +
          " value; " +
          suffix
        let definitions = "[Exposed=*] interface T {}; typedef T _Alias;"
        assert_eq(check_attribute_source(definitions + declaration), expected)
        assert_eq(check_attribute_source(declaration + definitions), expected)
      }
    }
  }
}

///|
test "SameObject accepts only non-nullable interface and object types after resolving typedefs" {
  let definitions = "[Exposed=*] interface T {}; dictionary D {}; enum E { \"value\" }; callback C = undefined (); callback interface CI { undefined run(); }; interface mixin M {}; namespace N {}; typedef object O; typedef object? MaybeObject; typedef T? MaybeInterface; typedef (T or DOMString) U; typedef (Cycle or DOMString) Cycle;"
  for
    (type_, expected) in [
      ("T", true),
      ("_T", true),
      ("object", true),
      ("O", true),
      ("T?", false),
      ("object?", false),
      ("O?", false),
      ("MaybeObject", false),
      ("MaybeInterface", false),
      ("long", false),
      ("DOMString", false),
      ("any", false),
      ("symbol", false),
      ("D", false),
      ("E", false),
      ("C", false),
      ("CI", false),
      ("M", false),
      ("N", false),
      ("Missing", false),
      ("Promise<T>", false),
      ("FrozenArray<T>", false),
      ("ObservableArray<T>", false),
      ("(T or DOMString)", false),
      ("U", false),
      ("Cycle", false),
    ] {
    assert_eq(
      check_attribute_source(
        definitions +
        "[Exposed=*] interface A { [SameObject] readonly attribute " +
        type_ +
        " value; };",
      ),
      expected,
    )
  }
  for
    definition in [
      "typedef object T;", "typedef long T;", "typedef Promise<long> T;", "typedef T T;",
    ] {
    let expected = definition == "typedef object T;"
    assert_eq(
      check_attribute_source(
        definition +
        "[Exposed=*] interface A { [SameObject] readonly attribute T value; };",
      ),
      expected,
    )
  }
}

///|
test "SameObject checks every marked attribute and only recognizes NoArgs" {
  for
    source in [
      "[Exposed=*] interface A { readonly attribute long first; [SameObject] readonly attribute long last; };",
      "[Exposed=*] interface A {}; [Exposed=*] interface B { [SameObject] readonly attribute long value; };",
      "[Exposed=*] interface A {}; partial interface A { [SameObject] readonly attribute long value; };",
      "[Exposed=*] interface A { [Example, SameObject] readonly attribute long value; };",
      "[Exposed=*] interface A { [SameObject, Example] readonly attribute long value; };",
    ] {
    assert_false(check_attribute_source(source))
  }
  for
    source in [
      "[Exposed=*] interface A { readonly attribute long value; };", "[Exposed=*] interface A { [SameObject=value] attribute long value; };",
      "[Exposed=*] interface A { [SameObject()] attribute long value; };", "[Exposed=*] interface A { [SameObject=(value)] attribute long value; };",
    ] {
    assert_true(check_attribute_source(source))
  }
}
