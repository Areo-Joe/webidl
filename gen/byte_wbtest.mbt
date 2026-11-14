///|
fn check_byte_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Byte constants require integer tokens within signed eight bit range" {
  for
    (prefix, suffix) in [
      ("[Exposed=*] interface A {", "};"),
      ("[Exposed=*] interface A {}; partial interface A {", "};"),
      ("partial interface A {", "}; [Exposed=*] interface A {};"),
      ("interface mixin M {", "};"),
      ("interface mixin M {}; partial interface mixin M {", "};"),
      ("partial interface mixin M {", "}; interface mixin M {};"),
      ("callback interface C { undefined run();", "};"),
    ] {
    for
      (value, valid) in [
        ("-128", true),
        ("127", true),
        ("0", true),
        ("-0", true),
        ("-129", false),
        ("128", false),
        ("0x7f", true),
        ("0X7F", true),
        ("-0x80", true),
        ("-0X80", true),
        ("0x80", false),
        ("-0x81", false),
        ("0177", true),
        ("-0200", true),
        ("0200", false),
        ("-0201", false),
        ("000177", true),
        ("-000200", true),
        ("000", true),
        ("-000", true),
        ("0x00007f", true),
        ("-0x000080", true),
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
        check_byte_source(
          prefix + " const byte VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Byte constant validation checks every constant and leaves other types unchanged" {
  assert_false(
    check_byte_source(
      "[Exposed=*] interface A { const byte FIRST = 0; const long COUNT = 128; const byte LAST = 128; };",
    ),
  )
  assert_false(
    check_byte_source(
      "[Exposed=*] interface A { const byte FIRST = 0; }; partial interface A { const byte LAST = -129; };",
    ),
  )
  assert_true(
    check_byte_source(
      "[Exposed=*] interface A { const byte LOW = -128; const byte HIGH = 127; const long COUNT = 128; const boolean READY = true; };",
    ),
  )
}
