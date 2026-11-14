///|
fn check_constant_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Constant type identifiers must reference typedefs of non nullable primitive types" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A {", "};"),
      ("[Exposed=*] interface A {}; partial interface A {", "};"),
      ("partial interface A {", "}; [Exposed=*] interface A {};"),
      ("interface mixin M {", "};"),
      ("interface mixin M {}; partial interface mixin M {", "};"),
      ("partial interface mixin M {", "}; interface mixin M {};"),
      ("callback interface C {", "};"),
    ] {
    for
      (type_, valid) in [
        ("boolean", true),
        ("byte", true),
        ("octet", true),
        ("short", true),
        ("unsigned short", true),
        ("long", true),
        ("unsigned long", true),
        ("long long", true),
        ("unsigned long long", true),
        ("float", true),
        ("unrestricted float", true),
        ("double", true),
        ("unrestricted double", true),
        ("bigint", true),
        ("[Clamp] long", true),
        ("long?", false),
        ("DOMString", false),
        ("ByteString", false),
        ("USVString", false),
        ("any", false),
        ("undefined", false),
        ("object", false),
        ("symbol", false),
        ("ArrayBuffer", false),
        ("sequence<long>", false),
        ("FrozenArray<long>", false),
        ("ObservableArray<long>", false),
        ("record<DOMString, long>", false),
        ("Promise<long>", false),
        ("(long or DOMString)", false),
      ] {
      let declaration = "typedef " + type_ + " Target;"
      let value = match type_ {
        "boolean" => "true"
        "float" | "unrestricted float" | "double" | "unrestricted double" =>
          "0.0"
        _ => "0"
      }
      let usage = prefix + " const Target VALUE = " + value + "; " + suffix
      assert_eq(check_constant_source(declaration + usage), valid)
      assert_eq(check_constant_source(usage + declaration), valid)
    }
    assert_false(
      check_constant_source(prefix + " const Missing VALUE = 0; " + suffix),
    )
  }
}

///|
test "Constant type lookup normalizes escaped identifiers" {
  for target in ["Target", "_Target"] {
    for reference in ["Target", "_Target"] {
      assert_true(
        check_constant_source(
          "typedef long " +
          target +
          "; [Exposed=*] interface A { const " +
          reference +
          " VALUE = 0; };",
        ),
      )
    }
  }
}

///|
test "Constant type identifiers cannot reference other definitions or typedefs of them" {
  for
    declaration in [
      "[Exposed=*] interface Target {};", "interface mixin Target {};", "namespace Target {};",
      "dictionary Target {};", "enum Target { \"value\" };", "callback Target = undefined ();",
      "callback interface Target {};",
    ] {
    assert_false(
      check_constant_source(
        declaration + "[Exposed=*] interface A { const Target VALUE = 0; };",
      ),
    )
    assert_false(
      check_constant_source(
        declaration +
        "typedef Target Alias; [Exposed=*] interface A { const Alias VALUE = 0; };",
      ),
    )
  }
  assert_false(
    check_constant_source(
      "typedef long Other; [Exposed=*] interface A { const Missing VALUE = 0; };",
    ),
  )
}
