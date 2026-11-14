///|
fn check_long_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Long constants require integer tokens within signed thirty two bit range" {
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
        ("-2147483648", true),
        ("2147483647", true),
        ("-2147483649", false),
        ("2147483648", false),
        ("0x7fffffff", true),
        ("0X7FFFFFFF", true),
        ("-0x80000000", true),
        ("0x80000000", false),
        ("-0X80000001", false),
        ("017777777777", true),
        ("-020000000000", true),
        ("020000000000", false),
        ("-020000000001", false),
        ("00017777777777", true),
        ("0x00007fffffff", true),
        ("-0x000080000000", true),
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
        check_long_source(
          prefix + " const long VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Long constant validation checks every constant and keeps integer type bounds distinct" {
  assert_false(
    check_long_source(
      "[Exposed=*] interface A { const long FIRST = 0; const unsigned long COUNT = 2147483648; const long LAST = 2147483648; };",
    ),
  )
  assert_false(
    check_long_source(
      "[Exposed=*] interface A { const long FIRST = 0; }; partial interface A { const long LAST = -2147483649; };",
    ),
  )
  assert_true(
    check_long_source(
      "[Exposed=*] interface A { const long HIGH = 2147483647; const long LOW = -2147483648; const unsigned long COUNT = 2147483648; const long long WIDE = -2147483649; const unsigned long long UNSIGNED_WIDE = 2147483648; const short SHORT = -32768; const unsigned short USHORT = 65535; };",
    ),
  )
  assert_false(
    check_long_source(
      "[Exposed=*] interface A { const long HIGH = 2147483647; const short VALUE = 32768; };",
    ),
  )
}
