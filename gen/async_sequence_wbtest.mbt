///|
fn check_async_sequence_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Attribute async sequence checks cover every declaration and attribute form" {
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
          ("async_sequence<long>", false),
          ("async_sequence<long>?", false),
          ("[Example] async_sequence<long>", false),
          ("Values", false),
          ("_Values?", false),
          ("MaybeValues", false),
          ("DOMString", true),
          ("Promise<async_sequence<long>>", true),
          ("Promise<Values>", true),
          ("(async_sequence<long> or boolean)", true),
          ("(Values or boolean)?", true),
          ("(MaybeValues or boolean)", true),
          ("((DOMString or Values) or boolean)?", true),
          ("ValueUnion", true),
          ("ValueUnion?", true),
        ] {
        let valid = valid &&
          (
            !type_.has_prefix("Promise<") ||
            form
            is ("readonly attribute"
            | "static readonly attribute"
            | "stringifier readonly attribute")
          )
        let declaration = attribute_declaration_source(
          prefix, suffix, form, type_,
        )
        let definitions = "typedef async_sequence<long> _Values; typedef async_sequence<long>? MaybeValues; typedef (Values or boolean) ValueUnion;"
        for source in [definitions + declaration, declaration + definitions] {
          assert_eq(check_async_sequence_source(source), valid)
        }
      }
    }
  }
}

///|
test "Async sequence attribute checks stop at union and container boundaries" {
  for
    source in [
      "typedef (Value or async_sequence<long>) Value; [Exposed=*] interface A { attribute Value value; };",
      "typedef Promise<Value> Value; [Exposed=*] interface A { readonly attribute Value value; };",
      "typedef async_sequence<long> Values; [Exposed=*] interface A { readonly attribute Promise<Values> values; };",
    ] {
    assert_true(check_async_sequence_source(source))
  }
  assert_false(
    check_async_sequence_source(
      "typedef (async_sequence<long> or sequence<long>) Value; [Exposed=*] interface A { attribute Value value; };",
    ),
  )
}

///|
test "Async sequence types remain permitted outside attribute and constant types" {
  for
    source in [
      "typedef async_sequence<long> Values;", "[Exposed=*] interface A { async_sequence<long>? get(); undefined use(async_sequence<long> values); constructor(async_sequence<long> values); };",
      "dictionary D { async_sequence<long> values; required async_sequence<long>? maybeValues; };",
      "callback C = async_sequence<long> (long value);",
    ] {
    assert_true(check_async_sequence_source(source))
  }
}

///|
test "Async sequence checks inspect every attribute" {
  for
    source in [
      "[Exposed=*] interface A { attribute long first; attribute async_sequence<long> last; };",
      "[Exposed=*] interface A {}; [Exposed=*] interface B { attribute async_sequence<long> value; };",
      "[Exposed=*] interface A {}; partial interface A { attribute long first; attribute async_sequence<long> last; };",
    ] {
    assert_false(check_async_sequence_source(source))
  }
}
