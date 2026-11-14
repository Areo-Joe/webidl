///|
fn check_short_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Short constants require integer tokens within signed sixteen bit range" {
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
        ("-32768", true),
        ("32767", true),
        ("-32769", false),
        ("32768", false),
        ("0x7fff", true),
        ("0X7FFF", true),
        ("-0x8000", true),
        ("0x8000", false),
        ("-0X8001", false),
        ("077777", true),
        ("-0100000", true),
        ("0100000", false),
        ("-0100001", false),
        ("00077777", true),
        ("0x00007fff", true),
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
        check_short_source(
          prefix + " const short VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Short constant validation checks every constant and keeps byte bounds distinct" {
  assert_false(
    check_short_source(
      "[Exposed=*] interface A { const short FIRST = 0; const long COUNT = 32768; const short LAST = 32768; };",
    ),
  )
  assert_false(
    check_short_source(
      "[Exposed=*] interface A { const short FIRST = 0; }; partial interface A { const short LAST = -32769; };",
    ),
  )
  assert_true(
    check_short_source(
      "[Exposed=*] interface A { const short HIGH = 32767; const short LOW = -32768; const octet OCTET = 255; const byte BYTE = -128; const unsigned short COUNT = 32768; const long LONG = 32768; const boolean READY = true; };",
    ),
  )
  assert_false(
    check_short_source(
      "[Exposed=*] interface A { const short HIGH = 32767; const byte VALUE = 128; };",
    ),
  )
}
