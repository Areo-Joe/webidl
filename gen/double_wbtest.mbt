///|
fn check_double_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Double constants require decimal tokens that round to finite double precision values" {
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
        ("0.0", true),
        ("-0.0", true),
        (".5", true),
        ("1.", true),
        ("1e0", true),
        ("1E+2", true),
        ("-1.25e-2", true),
        ("1e39", true),
        ("1.7976931348623157e308", true),
        ("-1.7976931348623157e308", true),
        ("1.7976931348623158e308", true),
        ("1.7976931348623159e308", false),
        ("-1.7976931348623159e308", false),
        (
          "179769313486231580793728971405303415079934132710037826936173778980444968292764750946649017977587207096330286416692887910946555547851940402630657488671505820681908902000708383676273854845817711531764475730270069855571366959622842914819860834936475292719074168444365510704342711559699508093042880177904174497791.0",
          true,
        ),
        (
          "179769313486231580793728971405303415079934132710037826936173778980444968292764750946649017977587207096330286416692887910946555547851940402630657488671505820681908902000708383676273854845817711531764475730270069855571366959622842914819860834936475292719074168444365510704342711559699508093042880177904174497792.0",
          false,
        ),
        (
          "-179769313486231580793728971405303415079934132710037826936173778980444968292764750946649017977587207096330286416692887910946555547851940402630657488671505820681908902000708383676273854845817711531764475730270069855571366959622842914819860834936475292719074168444365510704342711559699508093042880177904174497791.0",
          true,
        ),
        (
          "-179769313486231580793728971405303415079934132710037826936173778980444968292764750946649017977587207096330286416692887910946555547851940402630657488671505820681908902000708383676273854845817711531764475730270069855571366959622842914819860834936475292719074168444365510704342711559699508093042880177904174497792.0",
          false,
        ),
        ("5e-324", true),
        ("1e-324", true),
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
        check_double_source(
          prefix + " const double VALUE = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Double constant validation checks every constant and keeps floating point types distinct" {
  assert_false(
    check_double_source(
      "[Exposed=*] interface A { const double FIRST = 0.0; const double LAST = 1e309; };",
    ),
  )
  assert_false(
    check_double_source(
      "[Exposed=*] interface A { const double FIRST = 0.0; }; partial interface A { const double LAST = Infinity; };",
    ),
  )
  assert_true(
    check_double_source(
      "[Exposed=*] interface A { const double VALUE = 1e39; const float FINITE = 1.0; const unrestricted float FLOAT_INFINITY = Infinity; const unrestricted double DOUBLE_INFINITY = Infinity; const unrestricted double NAN_VALUE = NaN; };",
    ),
  )
  assert_false(
    check_double_source(
      "[Exposed=*] interface A { const double VALUE = 1e39; const float RESTRICTED = 1e39; };",
    ),
  )
}
