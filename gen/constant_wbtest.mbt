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
      ("[Exposed=*] namespace N {", "};"),
      ("[Exposed=*] namespace N {}; partial namespace N {", "};"),
      ("partial namespace N {", "}; [Exposed=*] namespace N {};"),
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
        ("async_sequence<long>", false),
        ("async_sequence<long>?", false),
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
test "Namespace constants use existing value checks and inspect every member" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] namespace N {", "};"),
      ("[Exposed=*] namespace N {}; partial namespace N {", "};"),
      ("partial namespace N {", "}; [Exposed=*] namespace N {};"),
    ] {
    for
      (body, valid) in [
        ("const boolean FLAG = true;", true),
        ("const boolean FLAG = 1;", false),
        ("const byte VALUE = 127;", true),
        ("const byte VALUE = 128;", false),
        ("const long FIRST = 1; const byte LAST = 128;", false),
        ("readonly attribute DOMString text; const byte VALUE = 128;", false),
        ("const long _constructor = 1;", false),
        ("const long _VALUE = 1;", true),
      ] {
      assert_eq(check_constant_source(prefix + body + suffix), valid)
    }
  }
  assert_false(
    check_constant_source(
      "[Exposed=*] namespace First { const long VALUE = 1; }; [Exposed=*] namespace Last { const byte VALUE = 128; };",
    ),
  )
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

///|
test "Typedef constants use the same primitive value checks as direct constants" {
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
      (type_, value, valid) in [
        ("boolean", "true", true),
        ("boolean", "0", false),
        ("byte", "-128", true),
        ("byte", "128", false),
        ("octet", "255", true),
        ("octet", "-1", false),
        ("short", "-32768", true),
        ("short", "32768", false),
        ("unsigned short", "65535", true),
        ("unsigned short", "65536", false),
        ("long", "-2147483648", true),
        ("long", "2147483648", false),
        ("unsigned long", "4294967295", true),
        ("unsigned long", "4294967296", false),
        ("long long", "-9223372036854775808", true),
        ("long long", "9223372036854775808", false),
        ("unsigned long long", "18446744073709551615", true),
        ("unsigned long long", "18446744073709551616", false),
        ("unsigned long long", "-0X0", true),
        ("unsigned long long", "-0x1", false),
        ("float", "1.0", true),
        ("float", "1e39", false),
        ("float", "Infinity", false),
        ("float", "340282356779733661637539395458142568447.0", true),
        ("unrestricted float", "Infinity", true),
        ("unrestricted float", "NaN", true),
        ("unrestricted float", "1", false),
        ("double", "1e39", true),
        ("double", "1e309", false),
        ("double", "NaN", false),
        ("unrestricted double", "-Infinity", true),
        ("unrestricted double", "1e9999", true),
        ("unrestricted double", "false", false),
        ("bigint", "999999999999999999999999999999999999999999", true),
        ("bigint", "1.0", false),
        ("[Clamp] byte", "127", true),
        ("[Clamp] byte", "128", false),
      ] {
      for target in ["Target", "_Target"] {
        for reference in ["Target", "_Target"] {
          let declaration = "typedef " + type_ + " " + target + ";"
          let usage = prefix +
            " const " +
            reference +
            " VALUE = " +
            value +
            "; " +
            suffix
          assert_eq(check_constant_source(declaration + usage), valid)
          assert_eq(check_constant_source(usage + declaration), valid)
        }
      }
    }
  }
}

///|
test "Typedef value checks inspect every constant and preserve direct checks" {
  assert_false(
    check_constant_source(
      "typedef byte Target; [Exposed=*] interface A { const Target FIRST = 0; const Target LAST = 128; };",
    ),
  )
  assert_false(
    check_constant_source(
      "typedef byte Target; [Exposed=*] interface A { const Target FIRST = 0; }; partial interface A { const Target LAST = 128; };",
    ),
  )
  assert_false(
    check_constant_source(
      "typedef byte Target; [Exposed=*] interface A { const Target FIRST = 0; const byte LAST = 128; };",
    ),
  )
  assert_true(
    check_constant_source(
      "typedef byte Small; typedef bigint Large; [Exposed=*] interface A { const Small FIRST = 127; const Large LAST = 18446744073709551616; };",
    ),
  )
}
