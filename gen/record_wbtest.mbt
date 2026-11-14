///|
fn check_record_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Attribute record checks cover every declaration and attribute form" {
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
          ("record<DOMString, long>", false),
          ("record<USVString, long>", false),
          ("record<ByteString, long>", false),
          ("record<DOMString, long>?", false),
          ("[Example] record<DOMString, long>", false),
          ("Values", false),
          ("_Values?", false),
          ("MaybeValues", false),
          ("ValueUnion", false),
          ("(record<DOMString, long> or DOMString)", false),
          ("(DOMString or record<DOMString, long>)?", false),
          ("((DOMString or Values) or boolean)", false),
          ("(DOMString or (boolean or Values)?)", false),
          ("([Example] Values or DOMString)", false),
          ("DOMString", true),
          ("Promise<record<DOMString, long>>", true),
          ("Promise<(sequence<Values> or DOMString)?>", true),
        ] {
        let valid = valid &&
          (
            !type_.has_prefix("Promise<") ||
            form
            is ("readonly attribute"
            | "static readonly attribute"
            | "stringifier readonly attribute")
          )
        let declaration = prefix + form + " " + type_ + " value; " + suffix
        let definitions = "typedef record<DOMString, long> _Values; typedef record<DOMString, long>? MaybeValues; typedef (Values or DOMString) ValueUnion;"
        for source in [definitions + declaration, declaration + definitions] {
          assert_eq(check_record_source(source), valid)
        }
      }
    }
  }
}

///|
test "Attribute record checks terminate on cycles and inspect other branches" {
  for
    type_definition in [
      "typedef (Value or record<DOMString, long>) Value;", "typedef (record<DOMString, long> or Value) Value;",
      "typedef (Other or DOMString) Value; typedef (Value or record<DOMString, long>) Other;",
    ] {
    assert_false(
      check_record_source(
        type_definition + "[Exposed=*] interface A { attribute Value value; };",
      ),
    )
  }
  assert_true(
    check_record_source(
      "typedef (Value or DOMString) Value; [Exposed=*] interface A { attribute Value value; };",
    ),
  )
  assert_true(
    check_record_source(
      "typedef record<DOMString, Value> Value; [Exposed=*] interface A { attribute FrozenArray<Value> value; };",
    ),
  )
}

///|
test "Record types remain permitted outside attribute and constant types" {
  for
    source in [
      "typedef record<DOMString, long> Values;", "[Exposed=*] interface A { record<DOMString, long> get(); undefined use(record<DOMString, long> values); constructor(record<DOMString, long> values); };",
      "dictionary D { record<DOMString, long> values; required record<DOMString, long>? maybeValues; };",
      "callback C = record<DOMString, long> (record<DOMString, long> values);", "[Exposed=*] interface A { readonly attribute Promise<record<DOMString, long>> values; };",
    ] {
    assert_true(check_record_source(source))
  }
}

///|
test "Record checks inspect every attribute" {
  for
    source in [
      "[Exposed=*] interface A { attribute long first; attribute record<DOMString, long> last; };",
      "[Exposed=*] interface A {}; [Exposed=*] interface B { attribute record<DOMString, long> value; };",
      "[Exposed=*] interface A {}; partial interface A { attribute long first; attribute record<DOMString, long> last; };",
    ] {
    assert_false(check_record_source(source))
  }
}
