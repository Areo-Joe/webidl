///|
fn check_sequence_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Attribute sequence checks cover every declaration and attribute form" {
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
      for
        (type_, valid) in [
          ("sequence<long>", false),
          ("sequence<long>?", false),
          ("[Example] sequence<long>", false),
          ("Values", false),
          ("_Values?", false),
          ("MaybeValues", false),
          ("ValueUnion", false),
          ("(sequence<long> or DOMString)", false),
          ("(DOMString or sequence<long>)?", false),
          ("((DOMString or Values) or boolean)", false),
          ("(DOMString or (boolean or Values)?)", false),
          ("([Example] Values or DOMString)", false),
          ("DOMString", true),
          ("FrozenArray<sequence<long>>", true),
          ("(FrozenArray<Values> or DOMString)?", true),
        ] {
        let declaration = prefix + form + " " + type_ + " value; " + suffix
        let definitions = "typedef sequence<long> _Values; typedef sequence<long>? MaybeValues; typedef (Values or DOMString) ValueUnion;"
        for source in [definitions + declaration, declaration + definitions] {
          assert_eq(check_sequence_source(source), valid)
        }
      }
    }
  }
}

///|
test "Attribute sequence checks terminate on cycles and inspect other branches" {
  for
    type_definition in [
      "typedef (Value or sequence<long>) Value;", "typedef (sequence<long> or Value) Value;",
      "typedef (Other or DOMString) Value; typedef (Value or sequence<long>) Other;",
    ] {
    assert_false(
      check_sequence_source(
        type_definition + "[Exposed=*] interface A { attribute Value value; };",
      ),
    )
  }
  assert_true(
    check_sequence_source(
      "typedef (Value or DOMString) Value; [Exposed=*] interface A { attribute Value value; };",
    ),
  )
  assert_true(
    check_sequence_source(
      "typedef sequence<Value> Value; [Exposed=*] interface A { attribute FrozenArray<Value> value; };",
    ),
  )
}

///|
test "Sequence types remain permitted outside attribute and constant types" {
  for
    source in [
      "typedef sequence<long> Values;", "[Exposed=*] interface A { sequence<long> get(); undefined use(sequence<long> values); constructor(sequence<long> values); };",
      "dictionary D { sequence<long> values; required sequence<long>? maybeValues; };",
      "callback C = sequence<long> (sequence<long> values);", "[Exposed=*] interface A { readonly attribute Promise<sequence<long>> values; };",
    ] {
    assert_true(check_sequence_source(source))
  }
}

///|
test "Sequence checks inspect every attribute" {
  for
    source in [
      "[Exposed=*] interface A { attribute long first; attribute sequence<long> last; };",
      "[Exposed=*] interface A {}; [Exposed=*] interface B { attribute sequence<long> value; };",
      "[Exposed=*] interface A {}; partial interface A { attribute long first; attribute sequence<long> last; };",
    ] {
    assert_false(check_sequence_source(source))
  }
}
