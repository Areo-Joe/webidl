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
test "Callback interfaces with constants require a valid Exposed annotation" {
  let globals = "[Exposed=*, Global=(Window,Worker)] interface G {};"
  for
    (attribute, valid) in [
      ("", false),
      ("[Exposed=*]", true),
      ("[Exposed=Window]", true),
      ("[Exposed=(Window,Worker)]", true),
      ("[Exposed=_Window]", true),
      ("[Exposed]", false),
      ("[Exposed()]", false),
      ("[Exposed=Name()]", false),
      ("[SecureContext]", false),
    ] {
    for
      constants in [
        "const long value = 1;", "const long first = 1; const long second = 2;",
      ] {
      assert_eq(
        check_callback_interface_source(
          globals +
          attribute +
          " callback interface C { " +
          constants +
          " undefined run(); };",
        ),
        valid,
      )
    }
    assert_true(
      check_callback_interface_source(
        globals + attribute + " callback interface C { undefined run(); };",
      ),
    )
  }
}

///|
test "Callback interface Exposed requirements are local to the definition" {
  for
    (source, expected) in [
      (
        "callback interface C { [Exposed=*] const long value = 1; undefined run(); };",
        false,
      ),
      (
        "callback interface C { const long value = 1; [Exposed=*] undefined run(); };",
        false,
      ),
      (
        "[Exposed=*] callback interface A { const long first = 1; undefined run(); }; callback interface B { const long second = 2; undefined run(); };",
        false,
      ),
      (
        "[Exposed=*] callback interface A { const long first = 1; undefined run(); }; callback interface B { undefined run(); };",
        true,
      ),
      (
        "[Exposed=*] interface A { const long value = 1; }; callback interface B { undefined run(); };",
        true,
      ),
    ] {
    assert_eq(check_callback_interface_source(source), expected)
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
