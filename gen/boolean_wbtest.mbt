///|
fn check_boolean_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Boolean constants require true or false in every constant declaration context" {
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
        ("true", true),
        ("false", true),
        ("0", false),
        ("1", false),
        ("-1", false),
        ("0x1", false),
        ("1.0", false),
        ("-0.0", false),
        ("NaN", false),
        ("Infinity", false),
        ("-Infinity", false),
      ] {
      assert_eq(
        check_boolean_source(
          prefix + " const boolean READY = " + value + "; " + suffix,
        ),
        valid,
      )
    }
  }
}

///|
test "Boolean constant validation checks every constant" {
  assert_false(
    check_boolean_source(
      "[Exposed=*] interface A { const boolean FIRST = true; const long COUNT = 1; const boolean LAST = 0; };",
    ),
  )
  assert_false(
    check_boolean_source(
      "[Exposed=*] interface A { const boolean FIRST = true; }; partial interface A { const boolean LAST = 0; };",
    ),
  )
  assert_true(
    check_boolean_source(
      "[Exposed=*] interface A { const boolean FIRST = true; const boolean LAST = false; };",
    ),
  )
}

///|
test "Boolean constant validation leaves other literal types unchanged" {
  assert_true(
    check_boolean_source(
      "[Exposed=*] interface A { const long COUNT = 1; const double VALUE = 1.5; const unrestricted double LIMIT = Infinity; };",
    ),
  )
}
