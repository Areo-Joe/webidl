///|
fn check_float_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Float constants require decimal tokens that round to finite single precision values" {
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
        ("3.4028236e38", false),
        ("-3.4028236e38", false),
        ("340282356779733661637539395458142568447.0", true),
        ("340282356779733661637539395458142568448.0", false),
        ("340282356779733661637539395458142568449.0", false),
        ("-340282356779733661637539395458142568447.0", true),
        ("-340282356779733661637539395458142568448.0", false),
        ("3.40282356779733661637539395458142568447e38", true),
        ("3.40282356779733661637539395458142568448E+38", false),
        ("0340282356779733661637539395458142568447.0", true),
        ("3402823567797336616375393954581425684470e-1", true),
        ("0.340282356779733661637539395458142568447e39", true),
        ("340282356779733661637539395458142568448e0", false),
        ("1.401298464324817e-45", true),
        ("1e-46", true),
        ("-1e-9999", true),
        ("1e9999", false),
        ("0e9999", true),
        ("1e-999999999999999999999999", true),
        ("1e999999999999999999999999", false),
        ("0", false),
        ("-0", false),
        ("1", false),
        ("0x1", false),
        ("01", false),
        ("true", false),
        ("false", false),
        ("NaN", false),
        ("Infinity", false),
        ("-Infinity", false),
      ] {
      assert_eq(
        check_float_source(
          prefix + " const float VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Float constant validation checks every constant and keeps floating point types distinct" {
  assert_false(
    check_float_source(
      "[Exposed=*] interface A { const float FIRST = 0.0; const float LAST = 1e39; };",
    ),
  )
  assert_false(
    check_float_source(
      "[Exposed=*] interface A { const float FIRST = 0.0; }; partial interface A { const float LAST = Infinity; };",
    ),
  )
  assert_true(
    check_float_source(
      "[Exposed=*] interface A { const float VALUE = 1.0; const unrestricted float WIDE = Infinity; const double DOUBLE = 1e39; const unrestricted double UNRESTRICTED = NaN; const long INTEGER = 1; };",
    ),
  )
  assert_false(
    check_float_source(
      "[Exposed=*] interface A { const float VALUE = 1.0; const long INTEGER = 1.0; };",
    ),
  )
}
