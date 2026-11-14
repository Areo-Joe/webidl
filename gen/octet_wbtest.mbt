///|
fn check_octet_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Octet constants require integer tokens within unsigned eight bit range" {
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
        ("127", true),
        ("128", true),
        ("255", true),
        ("-1", false),
        ("256", false),
        ("0xff", true),
        ("0XFF", true),
        ("0x100", false),
        ("-0x1", false),
        ("0377", true),
        ("0400", false),
        ("-01", false),
        ("000377", true),
        ("0x0000ff", true),
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
        check_octet_source(
          prefix + " const octet VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Octet constant validation checks every constant and keeps byte bounds distinct" {
  assert_false(
    check_octet_source(
      "[Exposed=*] interface A { const octet FIRST = 0; const long COUNT = 256; const octet LAST = 256; };",
    ),
  )
  assert_false(
    check_octet_source(
      "[Exposed=*] interface A { const octet FIRST = 0; }; partial interface A { const octet LAST = -1; };",
    ),
  )
  assert_true(
    check_octet_source(
      "[Exposed=*] interface A { const octet HIGH = 255; const byte LOW = -128; const long COUNT = 256; const boolean READY = true; };",
    ),
  )
  assert_false(
    check_octet_source(
      "[Exposed=*] interface A { const octet HIGH = 255; const byte VALUE = 128; };",
    ),
  )
}
