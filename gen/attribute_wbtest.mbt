///|
fn check_attribute_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Attribute type identifiers must reference permitted definitions" {
  for
    (definition, expected) in [
      ("[Exposed=*] interface T {};", true),
      ("enum T { \"value\" };", true),
      ("callback T = undefined ();", true),
      ("callback interface T { undefined run(); };", true),
      ("typedef long T;", true),
      ("", false),
      ("dictionary T {};", false),
      ("namespace T {};", false),
      ("interface mixin T {};", false),
    ] {
    for type_ in ["T", "T?", "_T", "_T?"] {
      for
        (prefix, suffix) in [
          ("[Exposed=*] interface A { attribute ", " value; };"),
          ("[Exposed=*] interface A { readonly attribute ", " value; };"),
          ("[Exposed=*] interface A { static attribute ", " value; };"),
          ("[Exposed=*] interface A { static readonly attribute ", " value; };"),
          (
            "[Exposed=*] interface A {}; partial interface A { attribute ", " value; };",
          ),
          ("interface mixin M { attribute ", " value; };"),
          (
            "interface mixin M {}; partial interface mixin M { attribute ", " value; };",
          ),
          ("[Exposed=*] namespace N { readonly attribute ", " value; };"),
          (
            "[Exposed=*] namespace N {}; partial namespace N { readonly attribute ",
            " value; };",
          ),
        ] {
        let declaration = prefix + type_ + suffix
        assert_eq(check_attribute_source(definition + declaration), expected)
        assert_eq(check_attribute_source(declaration + definition), expected)
      }
    }
  }
}

///|
test "Attribute identifier lookup normalizes definition names and keeps other type forms" {
  for
    source in [
      "typedef long _T; [Exposed=*] interface A { attribute T value; };", "[Exposed=*] interface _T {}; [Exposed=*] interface A { attribute T? value; };",
      "typedef DOMString T; [Exposed=*] interface A { stringifier attribute T value; };",
      "[Exposed=*] interface Parent { readonly attribute long value; }; [Exposed=*] interface A : Parent { inherit attribute long value; };",
      "[Exposed=*] interface A { attribute long first; attribute DOMString second; attribute object? third; attribute (long or DOMString) fourth; };",
      "typedef long T; interface mixin T {}; [Exposed=*] interface A { attribute T value; };",
    ] {
    assert_true(check_attribute_source(source))
  }
}

///|
test "Attributes cannot share identifiers with other members across declaration parts" {
  for
    other in [
      "attribute long _value;", "readonly attribute long _value;", "undefined _value();",
      "const long _value = 1;", "stringifier attribute DOMString _value;",
    ] {
    for
      (first, second) in [
        ("attribute long value;", other),
        (other, "attribute long value;"),
      ] {
      for
        source in [
          "[Exposed=*] interface A { " + first + second + " };",
          "[Exposed=*] interface A { " +
          first +
          " }; partial interface A { " +
          second +
          " };",
          "partial interface A { " +
          second +
          " }; [Exposed=*] interface A { " +
          first +
          " };",
          "[Exposed=*] interface A {}; partial interface A { " +
          first +
          " }; partial interface A { " +
          second +
          " };",
          "[Exposed=*] interface A { " +
          first +
          " }; interface mixin M { " +
          second +
          " }; A includes M;",
          "[Exposed=*] interface A {}; partial interface A { " +
          first +
          " }; interface mixin M {}; partial interface mixin M { " +
          second +
          " }; A includes M;",
          "[Exposed=*] interface A {}; interface mixin M { " +
          first +
          " }; interface mixin N { " +
          second +
          " }; A includes M; A includes N;",
        ] {
        assert_false(check_attribute_source(source))
      }
    }
  }
}

///|
test "Attribute conflicts include static inherit stringifier and named special members" {
  for
    attribute in [
      "attribute long value;", "readonly attribute long value;", "static attribute long value;",
      "static readonly attribute long value;", "stringifier attribute DOMString value;",
      "stringifier readonly attribute DOMString value;", "inherit attribute long value;",
    ] {
    for
      other in [
        "attribute long value;", "static attribute long value;", "undefined value();",
        "static undefined value();", "getter any value(DOMString key);", "setter undefined value(DOMString key, any data);",
        "deleter boolean value(DOMString key);",
      ] {
      assert_false(
        check_attribute_source(
          "[Exposed=*] interface A { " + attribute + other + " };",
        ),
      )
    }
  }
  assert_false(
    check_attribute_source(
      "[Exposed=*] interface A { attribute long required; undefined _required(); };",
    ),
  )
}

///|
test "Attribute conflicts exclude inherited members and unrelated definitions" {
  for
    source in [
      "[Exposed=*] interface A { attribute long first; undefined second(); const long third = 1; };",
      "[Exposed=*] interface A { attribute long value; getter any (DOMString key); stringifier; };",
      "[Exposed=*] interface A { attribute long value; }; [Exposed=*] interface B { attribute long value; };",
      "[Exposed=*] interface Parent { readonly attribute long value; }; [Exposed=*] interface A : Parent { inherit attribute long value; };",
      "[Exposed=*] interface Parent { attribute long value; }; [Exposed=*] interface A : Parent { attribute long value; };",
      "[Exposed=*] interface Parent { const long value = 1; }; [Exposed=*] interface A : Parent { attribute long value; };",
      "[Exposed=*] interface Parent {}; interface mixin M { attribute long value; }; Parent includes M; [Exposed=*] interface A : Parent { attribute long value; };",
      "[Exposed=*] interface A { attribute long value; }; interface mixin M { attribute long value; };",
      "[Exposed=*] interface A {}; [Exposed=*] interface B {}; interface mixin M { attribute long value; }; A includes M; B includes M;",
      "[Exposed=*] interface A { undefined run(long value); undefined run(DOMString value); };",
    ] {
    assert_true(check_attribute_source(source))
  }
}
