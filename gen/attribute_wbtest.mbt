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
