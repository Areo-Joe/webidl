///|
fn check_unrestricted_float_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Unrestricted float constants require floating point literals" {
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
        ("0.0", true),
        ("-0.0", true),
        (".5", true),
        ("1.", true),
        ("1e0", true),
        ("1E+2", true),
        ("-1.25e-2", true),
        ("3.4028234663852886e38", true),
        ("3.4028235e38", true),
        ("3.4028236e38", true),
        ("-3.4028236e38", true),
        ("340282356779733661637539395458142568447.0", true),
        ("340282356779733661637539395458142568448.0", true),
        ("340282356779733661637539395458142568449.0", true),
        ("-340282356779733661637539395458142568447.0", true),
        ("-340282356779733661637539395458142568448.0", true),
        ("3.40282356779733661637539395458142568447e38", true),
        ("3.40282356779733661637539395458142568448E+38", true),
        ("0340282356779733661637539395458142568447.0", true),
        ("3402823567797336616375393954581425684470e-1", true),
        ("0.340282356779733661637539395458142568447e39", true),
        ("340282356779733661637539395458142568448e0", true),
        ("1.401298464324817e-45", true),
        ("1e-46", true),
        ("-1e-9999", true),
        ("1e9999", true),
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
        check_unrestricted_float_source(
          prefix + " const unrestricted float VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Unrestricted float constant validation checks every constant and keeps float restrictions distinct" {
  assert_false(
    check_unrestricted_float_source(
      "[Exposed=*] interface A { const unrestricted float FIRST = Infinity; const unrestricted float LAST = 1; };",
    ),
  )
  assert_false(
    check_unrestricted_float_source(
      "[Exposed=*] interface A { const unrestricted float FIRST = NaN; }; partial interface A { const unrestricted float LAST = true; };",
    ),
  )
  assert_true(
    check_unrestricted_float_source(
      "[Exposed=*] interface A { const unrestricted float POSITIVE = Infinity; const unrestricted float NEGATIVE = -Infinity; const unrestricted float NAN_VALUE = NaN; const unrestricted float OVERFLOW = 1e9999; const float FINITE = 1.0; };",
    ),
  )
  for value in ["Infinity", "-Infinity", "NaN", "1e39"] {
    assert_false(
      check_unrestricted_float_source(
        "[Exposed=*] interface A { const unrestricted float VALUE = " +
        value +
        "; const float RESTRICTED = " +
        value +
        "; };",
      ),
    )
  }
}
