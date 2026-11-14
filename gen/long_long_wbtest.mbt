///|
fn check_long_long_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Long long constants require integer tokens within signed sixty four bit range" {
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
      (value, valid) in [
        ("0", true),
        ("-0", true),
        ("-9223372036854775808", true),
        ("9223372036854775807", true),
        ("-9223372036854775809", false),
        ("9223372036854775808", false),
        ("0x7fffffffffffffff", true),
        ("0X7FFFFFFFFFFFFFFF", true),
        ("-0x8000000000000000", true),
        ("0x8000000000000000", false),
        ("-0X8000000000000001", false),
        ("0777777777777777777777", true),
        ("-01000000000000000000000", true),
        ("01000000000000000000000", false),
        ("-01000000000000000000001", false),
        ("000777777777777777777777", true),
        ("0x00007fffffffffffffff", true),
        ("-0x00008000000000000000", true),
        ("000", true),
        ("-000", true),
        ("0x0", true),
        ("-0X0", true),
        ("true", false),
        ("false", false),
        ("1.0", false),
        ("1e0", false),
        ("NaN", false),
        ("Infinity", false),
        ("-Infinity", false),
        ("9999999999999999999999999999999999999999", false),
        ("-9999999999999999999999999999999999999999", false),
        ("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", false),
        ("07777777777777777777777777777777777777777", false),
      ] {
      assert_eq(
        check_long_long_source(
          prefix + " const long long VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Long long constant validation checks every constant and keeps integer type bounds distinct" {
  assert_false(
    check_long_long_source(
      "[Exposed=*] interface A { const long long FIRST = 0; const unsigned long long COUNT = 9223372036854775808; const long long LAST = 9223372036854775808; };",
    ),
  )
  assert_false(
    check_long_long_source(
      "[Exposed=*] interface A { const long long FIRST = 0; }; partial interface A { const long long LAST = -9223372036854775809; };",
    ),
  )
  assert_true(
    check_long_long_source(
      "[Exposed=*] interface A { const long long HIGH = 9223372036854775807; const long long LOW = -9223372036854775808; const unsigned long long WIDE = 9223372036854775808; const long LONG = -2147483648; const unsigned long ULONG = 4294967295; };",
    ),
  )
  assert_false(
    check_long_long_source(
      "[Exposed=*] interface A { const long long HIGH = 9223372036854775807; const long VALUE = 2147483648; };",
    ),
  )
}
