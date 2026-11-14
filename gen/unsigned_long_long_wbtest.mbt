///|
fn check_unsigned_long_long_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Unsigned long long constants require integer tokens within unsigned sixty four bit range" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A {", "};"),
      ("[Exposed=*] interface A {}; partial interface A {", "};"),
      ("partial interface A {", "}; [Exposed=*] interface A {};"),
      ("interface mixin M {", "};"),
      ("interface mixin M {}; partial interface mixin M {", "};"),
      ("partial interface mixin M {", "}; interface mixin M {};"),
      ("[Exposed=*] callback interface C { undefined run();", "};"),
    ] {
    for
      (value, valid) in [
        ("0", true),
        ("-0", true),
        ("9223372036854775807", true),
        ("9223372036854775808", true),
        ("18446744073709551615", true),
        ("-1", false),
        ("-18446744073709551615", false),
        ("18446744073709551616", false),
        ("0xffffffffffffffff", true),
        ("0XFFFFFFFFFFFFFFFF", true),
        ("0x10000000000000000", false),
        ("-0x1", false),
        ("-0xffffffffffffffff", false),
        ("01777777777777777777777", true),
        ("02000000000000000000000", false),
        ("-01", false),
        ("0001777777777777777777777", true),
        ("0x0000ffffffffffffffff", true),
        ("000", true),
        ("-000", true),
        ("0x0", true),
        ("-0X0", true),
        ("-0x0000", true),
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
        check_unsigned_long_long_source(
          prefix + " const unsigned long long VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Unsigned long long constant validation checks every constant and keeps signed long long bounds distinct" {
  assert_false(
    check_unsigned_long_long_source(
      "[Exposed=*] interface A { const unsigned long long FIRST = 0; const unsigned long long LAST = 18446744073709551616; };",
    ),
  )
  assert_false(
    check_unsigned_long_long_source(
      "[Exposed=*] interface A { const unsigned long long FIRST = 0; }; partial interface A { const unsigned long long LAST = -1; };",
    ),
  )
  assert_true(
    check_unsigned_long_long_source(
      "[Exposed=*] interface A { const unsigned long long HIGH = 18446744073709551615; const long long LOW = -9223372036854775808; const long long SIGNED_HIGH = 9223372036854775807; const unsigned long ULONG = 4294967295; };",
    ),
  )
  assert_false(
    check_unsigned_long_long_source(
      "[Exposed=*] interface A { const unsigned long long HIGH = 18446744073709551615; const long long VALUE = 9223372036854775808; };",
    ),
  )
}
