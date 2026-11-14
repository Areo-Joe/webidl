///|
fn check_unrestricted_double_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Unrestricted double constants require floating point literals" {
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
        ("0.0", true),
        ("-0.0", true),
        (".5", true),
        ("1.", true),
        ("1e0", true),
        ("1E+2", true),
        ("-1.25e-2", true),
        ("1e39", true),
        ("1.7976931348623157e308", true),
        ("1.7976931348623158e308", true),
        ("1.7976931348623159e308", true),
        ("-1.7976931348623159e308", true),
        ("5e-324", true),
        ("1e-324", true),
        ("-1e-9999", true),
        ("1e9999", true),
        ("-1e9999", true),
        ("0e9999", true),
        ("1e-999999999999999999999999", true),
        ("1e999999999999999999999999", true),
        ("0", false),
        ("-0", false),
        ("1", false),
        ("0x1", false),
        ("01", false),
        ("true", false),
        ("false", false),
        ("NaN", true),
        ("Infinity", true),
        ("-Infinity", true),
      ] {
      assert_eq(
        check_unrestricted_double_source(
          prefix + " const unrestricted double VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Unrestricted double constant validation checks every constant and keeps double restrictions distinct" {
  assert_false(
    check_unrestricted_double_source(
      "[Exposed=*] interface A { const unrestricted double FIRST = Infinity; const unrestricted double LAST = 1; };",
    ),
  )
  assert_false(
    check_unrestricted_double_source(
      "[Exposed=*] interface A { const unrestricted double FIRST = NaN; }; partial interface A { const unrestricted double LAST = true; };",
    ),
  )
  assert_true(
    check_unrestricted_double_source(
      "[Exposed=*] interface A { const unrestricted double POSITIVE = Infinity; const unrestricted double NEGATIVE = -Infinity; const unrestricted double NAN_VALUE = NaN; const unrestricted double OVERFLOW = 1e9999; const double FINITE = 1.0; };",
    ),
  )
  for value in ["Infinity", "-Infinity", "NaN", "1e309"] {
    assert_false(
      check_unrestricted_double_source(
        "[Exposed=*] interface A { const unrestricted double VALUE = " +
        value +
        "; const double RESTRICTED = " +
        value +
        "; };",
      ),
    )
  }
}
