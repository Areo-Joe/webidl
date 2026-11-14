///|
fn check_bigint_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Bigint constants require integer tokens without a range limit" {
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
        ("-1", true),
        ("-18446744073709551615", true),
        ("18446744073709551616", true),
        ("0xffffffffffffffff", true),
        ("0XFFFFFFFFFFFFFFFF", true),
        ("0x10000000000000000", true),
        ("-0x1", true),
        ("-0xffffffffffffffff", true),
        ("01777777777777777777777", true),
        ("02000000000000000000000", true),
        ("-01", true),
        ("0001777777777777777777777", true),
        ("0x0000ffffffffffffffff", true),
        ("000", true),
        ("-000", true),
        ("0x0", true),
        ("-0X0", true),
        ("-0x0000", true),
        ("-0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", true),
        ("-07777777777777777777777777777777777777777", true),
        ("1e0", false),
        ("1.0", false),
        ("true", false),
        ("false", false),
        ("NaN", false),
        ("Infinity", false),
        ("-Infinity", false),
        ("9999999999999999999999999999999999999999", true),
        ("-9999999999999999999999999999999999999999", true),
        ("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", true),
        ("07777777777777777777777777777777777777777", true),
      ] {
      assert_eq(
        check_bigint_source(
          prefix + " const bigint VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Bigint constant validation checks every constant and keeps integer type bounds distinct" {
  assert_false(
    check_bigint_source(
      "[Exposed=*] interface A { const bigint FIRST = 18446744073709551616; const bigint LAST = 1.0; };",
    ),
  )
  assert_false(
    check_bigint_source(
      "[Exposed=*] interface A { const bigint FIRST = 0; }; partial interface A { const bigint LAST = true; };",
    ),
  )
  assert_true(
    check_bigint_source(
      "[Exposed=*] interface A { const bigint HIGH = 18446744073709551616; const bigint LOW = -9223372036854775809; const long long SIGNED = -9223372036854775808; const unsigned long long UNSIGNED = 18446744073709551615; };",
    ),
  )
  assert_false(
    check_bigint_source(
      "[Exposed=*] interface A { const bigint HIGH = 18446744073709551616; const unsigned long long VALUE = 18446744073709551616; };",
    ),
  )
  assert_false(
    check_bigint_source(
      "[Exposed=*] interface A { const bigint LOW = -9223372036854775809; const long long VALUE = -9223372036854775809; };",
    ),
  )
}
