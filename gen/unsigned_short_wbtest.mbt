///|
fn check_unsigned_short_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Unsigned short constants require integer tokens within unsigned sixteen bit range" {
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
        ("32767", true),
        ("32768", true),
        ("65535", true),
        ("-1", false),
        ("65536", false),
        ("0xffff", true),
        ("0XFFFF", true),
        ("0x10000", false),
        ("-0x1", false),
        ("0177777", true),
        ("0200000", false),
        ("-01", false),
        ("000177777", true),
        ("0x0000ffff", true),
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
        check_unsigned_short_source(
          prefix + " const unsigned short VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Unsigned short constant validation checks every constant and keeps signed short bounds distinct" {
  assert_false(
    check_unsigned_short_source(
      "[Exposed=*] interface A { const unsigned short FIRST = 0; const long COUNT = 65536; const unsigned short LAST = 65536; };",
    ),
  )
  assert_false(
    check_unsigned_short_source(
      "[Exposed=*] interface A { const unsigned short FIRST = 0; }; partial interface A { const unsigned short LAST = -1; };",
    ),
  )
  assert_true(
    check_unsigned_short_source(
      "[Exposed=*] interface A { const unsigned short HIGH = 65535; const short LOW = -32768; const octet OCTET = 255; const byte BYTE = -128; const unsigned short COUNT = 32768; const long LONG = 65536; const boolean READY = true; };",
    ),
  )
  assert_false(
    check_unsigned_short_source(
      "[Exposed=*] interface A { const unsigned short HIGH = 65535; const short VALUE = 32768; };",
    ),
  )
}
