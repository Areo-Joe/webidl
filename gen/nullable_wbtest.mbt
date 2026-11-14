///|
fn check_nullable_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Typedef targets reject nullable observable arrays at every nesting level" {
  for
    type_ in [
      "ObservableArray<long>?", "[Example] ObservableArray<long>?", "sequence<ObservableArray<long>?>",
      "async_sequence<ObservableArray<long>?>", "FrozenArray<ObservableArray<long>?>",
      "ObservableArray<ObservableArray<long>?>", "record<DOMString, ObservableArray<long>?>",
      "Promise<ObservableArray<long>?>", "(ObservableArray<long>? or DOMString)",
      "(DOMString or ObservableArray<long>?)", "(DOMString or long or ObservableArray<long>?)",
      "((ObservableArray<long>? or long) or DOMString)", "sequence<Promise<record<DOMString, ObservableArray<long>?>>>",
    ] {
    assert_false(check_nullable_source("typedef " + type_ + " Target;"))
  }
}

///|
test "Nullable observable array checks distinguish array and element nullability" {
  for
    type_ in [
      "ObservableArray<long>", "ObservableArray<long?>", "ObservableArray<DOMString?>",
      "sequence<ObservableArray<long>>?", "FrozenArray<ObservableArray<long?>>",
      "record<DOMString, ObservableArray<long?>>", "Promise<ObservableArray<long?>>",
      "(ObservableArray<long> or DOMString)", "long?", "DOMString?",
    ] {
    assert_true(check_nullable_source("typedef " + type_ + " Target;"))
  }
}

///|
test "Nullable observable array checks inspect every typedef target" {
  assert_false(
    check_nullable_source(
      "typedef long First; typedef ObservableArray<long>? Last;",
    ),
  )
  assert_false(
    check_nullable_source(
      "typedef ObservableArray<long>? First; typedef long Last;",
    ),
  )
  assert_false(check_nullable_source("typedef ObservableArray<long>? _Target;"))
}

///|
test "Attribute nullable observable array checks cover every declaration and attribute form" {
  for
    (prefix, suffix, forms) in [
      (
        "[Exposed=*] interface A {",
        "};",
        [
          "attribute", "readonly attribute", "static attribute", "static readonly attribute",
          "inherit attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      (
        "[Exposed=*] interface A {}; partial interface A {",
        "};",
        [
          "attribute", "readonly attribute", "static attribute", "static readonly attribute",
          "inherit attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      (
        "partial interface A {",
        "}; [Exposed=*] interface A {};",
        [
          "attribute", "readonly attribute", "static attribute", "static readonly attribute",
          "inherit attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      (
        "interface mixin M {",
        "};",
        [
          "attribute", "readonly attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      (
        "interface mixin M {}; partial interface mixin M {",
        "};",
        [
          "attribute", "readonly attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      (
        "partial interface mixin M {",
        "}; interface mixin M {};",
        [
          "attribute", "readonly attribute", "stringifier attribute", "stringifier readonly attribute",
        ],
      ),
      ("namespace N {", "};", ["readonly attribute"]),
      ("namespace N {}; partial namespace N {", "};", ["readonly attribute"]),
      ("partial namespace N {", "}; namespace N {};", ["readonly attribute"]),
    ] {
    for form in forms {
      assert_false(
        check_nullable_source(
          prefix + " " + form + " ObservableArray<long>? items; " + suffix,
        ),
      )
      assert_true(
        check_nullable_source(
          prefix + " " + form + " DOMString text; " + suffix,
        ),
      )
    }
  }
}

///|
test "Attribute checks visit nested types and distinguish element nullability" {
  for
    (type_, valid) in [
      ("ObservableArray<long>?", false),
      ("FrozenArray<ObservableArray<long>?>", false),
      ("sequence<ObservableArray<long>?>", false),
      ("async_sequence<ObservableArray<long>?>", false),
      ("record<DOMString, ObservableArray<long>?>", false),
      ("Promise<ObservableArray<long>?>", false),
      ("(DOMString or ObservableArray<long>?)", false),
      ("((long or ObservableArray<long>?) or DOMString)", false),
      ("[Example] ObservableArray<long>?", false),
      ("ObservableArray<long>", true),
      ("ObservableArray<long?>", true),
      ("DOMString?", true),
    ] {
    assert_eq(
      check_nullable_source(
        "[Exposed=*] interface A { attribute " + type_ + " items; };",
      ),
      valid,
    )
  }
}

///|
test "Nullable observable array checks inspect every attribute" {
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A { attribute DOMString first; attribute ObservableArray<long>? last; };",
    ),
  )
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A { attribute DOMString first; }; partial interface A { attribute ObservableArray<long>? last; };",
    ),
  )
  assert_false(
    check_nullable_source(
      "[Exposed=*] interface A { attribute ObservableArray<long>? _items; };",
    ),
  )
}
