///|
fn check_callback_interface_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Callback interfaces must declare exactly one regular operation" {
  for
    (members, expected) in [
      ("", false),
      ("undefined run();", true),
      ("undefined run(); undefined other();", false),
      ("undefined run(long value); undefined run(DOMString value);", false),
      ("undefined run(long value); undefined _run(DOMString value);", false),
      ("[SecureContext] undefined run(optional long value);", true),
      ("undefined run(long... values);", true),
    ] {
    assert_eq(
      check_callback_interface_source(
        "callback interface Listener { " + members + " };",
      ),
      expected,
    )
  }
}

///|
test "Callback interface operation counts exclude constants" {
  for
    (members, expected) in [
      ("const long value = 1;", false),
      ("const long first = 1; const long second = 2;", false),
      ("const long value = 1; undefined run();", true),
      ("undefined run(); const long value = 1;", true),
      ("const long first = 1; undefined run(); const long second = 2;", true),
      ("const long value = 1; undefined first(); undefined second();", false),
    ] {
    assert_eq(
      check_callback_interface_source(
        "[Exposed=*] callback interface Listener { " + members + " };",
      ),
      expected,
    )
  }
}

///|
test "Callback interface operation counts are independent of other definitions" {
  assert_true(
    check_callback_interface_source(
      "callback interface A { undefined run(); }; callback interface B { undefined run(); };",
    ),
  )
  assert_false(
    check_callback_interface_source(
      "callback interface A {}; callback interface B { undefined first(); undefined second(); };",
    ),
  )
  assert_true(
    check_callback_interface_source(
      "[Exposed=*] interface A {}; interface mixin M {}; callback F = undefined ();",
    ),
  )
}
