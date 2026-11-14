///|
test "Inherited getters require the closest same-name ancestor attribute to be read only" {
  for
    (parent, expected) in [
      ("readonly attribute long value;", true),
      ("attribute long value;", false),
      ("static readonly attribute long value;", true),
      ("static attribute long value;", false),
      ("readonly attribute DOMString value;", false),
      ("readonly attribute long other;", false),
      ("", false),
    ] {
    let base = "[Exposed=*] interface Parent { " + parent + " };"
    for
      declaration in [
        "[Exposed=*] interface A : Parent { inherit attribute long _value; };", "[Exposed=*] interface A : Parent {}; partial interface A { inherit attribute long _value; };",
      ] {
      assert_eq(check_attribute_source(base + declaration), expected)
      assert_eq(check_attribute_source(declaration + base), expected)
    }
  }
  assert_false(
    check_attribute_source(
      "[Exposed=*] interface A { inherit attribute long value; };",
    ),
  )
  let grandparent = "[Exposed=*] interface Grandparent { readonly attribute long value; };"
  for
    (parent, expected) in [
      ("", true),
      ("readonly attribute long value;", true),
      ("readonly attribute DOMString value;", false),
      ("attribute long value;", false),
      ("static readonly attribute long value;", true),
      ("static readonly attribute DOMString value;", false),
      ("static attribute long value;", false),
      ("inherit attribute long value;", false),
    ] {
    assert_eq(
      check_attribute_source(
        grandparent +
        "[Exposed=*] interface Parent : Grandparent {" +
        parent +
        "}; [Exposed=*] interface A : Parent { inherit attribute long value; };",
      ),
      expected,
    )
  }
}

///|
test "Inherited getters include ancestor partials and included mixin members" {
  for
    members in [
      "[Exposed=*] interface Parent {}; partial interface Parent { readonly attribute DOMString value; };",
      "[Exposed=*] interface Parent {}; interface mixin M { readonly attribute DOMString value; }; Parent includes M;",
      "[Exposed=*] interface Parent {}; interface mixin M {}; partial interface mixin M { readonly attribute DOMString value; }; Parent includes M;",
      "[Exposed=*] interface Parent { stringifier readonly attribute DOMString value; };",
    ] {
    assert_true(
      check_attribute_source(
        members +
        "[Exposed=*] interface A : Parent { inherit attribute DOMString value; };",
      ),
    )
    assert_true(
      check_attribute_source(
        "[Exposed=*] interface A : Parent {}; partial interface A { inherit attribute DOMString value; };" +
        members,
      ),
    )
  }
  for
    source in [
      "[Exposed=*] interface Parent {}; interface mixin M { readonly attribute long value; }; [Exposed=*] interface A : Parent { inherit attribute long value; };",
      "[Exposed=*] interface Other { readonly attribute long value; }; [Exposed=*] interface Parent {}; [Exposed=*] interface A : Parent { inherit attribute long value; };",
      "[Exposed=*] interface Parent {}; [Exposed=*] interface A : Parent { readonly attribute long own; inherit attribute long value; };",
    ] {
    assert_false(check_attribute_source(source))
  }
}

///|
test "Inherited getter types resolve typedefs and compare annotations and nullability" {
  for
    (parent_type, child_type, expected) in [
      ("Value", "long", true),
      ("long", "_Value", true),
      ("long?", "Value?", true),
      ("long?", "Value", false),
      ("long", "Value?", false),
      ("[Clamp] long", "Clamped", true),
      ("Clamped", "[Clamp] long", true),
      ("[Clamp] long", "long", false),
      ("long", "[Clamp] long", false),
      ("(long or DOMString)", "(DOMString or long)", true),
      ("(long or DOMString)", "(boolean or DOMString)", false),
    ] {
    assert_eq(
      check_attribute_source(
        "typedef long Value; typedef [Clamp] long Clamped; [Exposed=*] interface Parent { readonly attribute " +
        parent_type +
        " _value; }; [Exposed=*] interface A : Parent { inherit attribute " +
        child_type +
        " value; };",
      ),
      expected,
    )
  }
}

///|
test "Attribute dictionary checks resolve typedefs and flattened union members" {
  let definitions = "dictionary _D {}; typedef D Value; typedef D? MaybeValue; typedef (D or DOMString) ValueUnion;"
  for
    type_ in [
      "D", "_D?", "Value", "Value?", "MaybeValue", "ValueUnion", "ValueUnion?", "(D or DOMString)",
      "((DOMString or Value) or boolean)", "(DOMString or (boolean or Value)?)",
      "([Example] Value or DOMString)",
    ] {
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
        ("namespace N { readonly attribute ", " value; };"),
        (
          "namespace N {}; partial namespace N { readonly attribute ", " value; };",
        ),
      ] {
      let declaration = prefix + type_ + suffix
      assert_false(check_attribute_source(definitions + declaration))
      assert_false(check_attribute_source(declaration + definitions))
    }
  }
}

///|
test "Attribute dictionary checks terminate on cycles and inspect other branches" {
  for
    definition in [
      "typedef (Value or D) Value;", "typedef (D or Value) Value;", "typedef (Other or DOMString) Value; typedef (Value or D) Other;",
    ] {
    assert_false(
      check_attribute_source(
        "dictionary D {}; " +
        definition +
        "[Exposed=*] interface A { attribute Value value; };",
      ),
    )
  }
  assert_true(
    check_attribute_source(
      "typedef (Value or DOMString) Value; [Exposed=*] interface A { attribute Value value; };",
    ),
  )
}

///|
test "Attribute dictionary checks preserve nested types and other type uses" {
  for
    source in [
      "dictionary D {}; [Exposed=*] interface A { readonly attribute Promise<D> value; };",
      "dictionary D {}; typedef D Value; [Exposed=*] interface A { readonly attribute Promise<(Value or DOMString)> value; };",
      "dictionary D {}; [Exposed=*] interface A { D get(); undefined use(D value); constructor(D value); };",
      "dictionary D {}; dictionary Other { D value; };", "dictionary D {}; callback C = D (D value);",
    ] {
    assert_true(check_attribute_source(source))
  }
  for
    source in [
      "dictionary D {}; typedef D Value; [Exposed=*] interface A { attribute long first; attribute Value last; };",
      "dictionary D {}; typedef D Value; [Exposed=*] interface A {}; [Exposed=*] interface B { attribute Value value; };",
    ] {
    assert_false(check_attribute_source(source))
  }
}

///|
fn attribute_declaration_source(
  prefix : String,
  suffix : String,
  form : String,
  type_ : String,
  name~ : String = "value",
) -> String {
  let declaration = prefix +
    " " +
    form +
    " " +
    type_ +
    " " +
    name +
    "; " +
    suffix
  if form == "inherit attribute" {
    "[Exposed=*] interface AttributeParent { readonly attribute " +
    type_ +
    " " +
    name +
    "; };" +
    declaration.replace(
      old="[Exposed=*] interface A",
      new="[Exposed=*] interface A : AttributeParent",
    )
  } else {
    declaration
  }
}

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
