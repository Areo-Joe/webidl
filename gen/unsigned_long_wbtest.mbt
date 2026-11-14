///|
fn check_unsigned_long_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Unsigned long constants require integer tokens within unsigned thirty two bit range" {
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
        ("2147483647", true),
        ("2147483648", true),
        ("4294967295", true),
        ("-1", false),
        ("4294967296", false),
        ("0xffffffff", true),
        ("0XFFFFFFFF", true),
        ("0x100000000", false),
        ("-0x1", false),
        ("037777777777", true),
        ("040000000000", false),
        ("-01", false),
        ("00037777777777", true),
        ("0x0000ffffffff", true),
        ("000", true),
        ("-000", true),
        ("0x0", true),
        ("-0X0", true),
        ("9223372036854775807", false),
        ("-9223372036854775808", false),
        ("9223372036854775808", false),
        ("-9223372036854775809", false),
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
        check_unsigned_long_source(
          prefix + " const unsigned long VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Unsigned long constant validation checks every constant and keeps signed long bounds distinct" {
  assert_false(
    check_unsigned_long_source(
      "[Exposed=*] interface A { const unsigned long FIRST = 0; const long long COUNT = 4294967296; const unsigned long LAST = 4294967296; };",
    ),
  )
  assert_false(
    check_unsigned_long_source(
      "[Exposed=*] interface A { const unsigned long FIRST = 0; }; partial interface A { const unsigned long LAST = -1; };",
    ),
  )
  assert_true(
    check_unsigned_long_source(
      "[Exposed=*] interface A { const unsigned long HIGH = 4294967295; const long LOW = -2147483648; const long long WIDE = 4294967296; const unsigned long long UNSIGNED_WIDE = 4294967296; const short SHORT = -32768; const unsigned short USHORT = 65535; };",
    ),
  )
  assert_false(
    check_unsigned_long_source(
      "[Exposed=*] interface A { const unsigned long HIGH = 4294967295; const long VALUE = 2147483648; };",
    ),
  )
}
