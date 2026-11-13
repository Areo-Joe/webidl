///|
fn check_exposed_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "Exposed interface validation matches global names and rejects duplicates" {
  let globals = "[Exposed=*, Global=Window] interface WindowGlobal {}; [Exposed=*, Global=(Worker,DedicatedWorker)] interface WorkerGlobal {};"
  for
    (source, valid) in [
      ("[Exposed=Window] interface A {};", true),
      ("[Exposed=(Window,Worker,DedicatedWorker)] interface A {};", true),
      ("[Exposed=*] interface A {};", true),
      ("[Exposed=Unknown] interface A {};", false),
      ("[Exposed=WindowGlobal] interface A {};", false),
      ("[Exposed=(Window,Unknown)] interface A {};", false),
      ("[Exposed=(Window,Window)] interface A {};", false),
      ("[Exposed=(_Window,Window)] interface A {};", false),
    ] {
    // Global definitions may follow their use.
    assert_eq(check_exposed_source(source + globals), valid)
  }
  assert_true(check_exposed_source("[Exposed=*] interface A {};"))
  assert_true(check_exposed_source("interface A {};"))
  assert_true(
    check_exposed_source(
      "[Exposed=_Window] interface A {}; [Exposed=*, Global=_Window] interface W {};",
    ),
  )
}

///|
test "Exposed member validation checks names and interface subsets" {
  let globals = "[Exposed=*, Global=Window] interface W {}; [Exposed=*, Global=Worker] interface G {};"
  for
    body in [
      "undefined f();", "readonly attribute boolean value;", "const long value = 1;",
      "constructor();",
    ] {
    for
      (interface_attrs, member_attrs, valid) in [
        ("[Exposed=(Window,Worker)]", "[Exposed=Window]", true),
        ("[Exposed=Window]", "[Exposed=Window]", true),
        ("[Exposed=Window]", "", true),
        ("[Exposed=*]", "[Exposed=Worker]", true),
        ("[Exposed=*]", "[Exposed=*]", true),
        ("[Exposed=Window]", "[Exposed=Worker]", false),
        ("[Exposed=Window]", "[Exposed=*]", false),
        ("[Exposed=*]", "[Exposed=Unknown]", false),
        ("[Exposed=*]", "[Exposed=(Window,Window)]", false),
      ] {
      let source = globals +
        interface_attrs +
        " interface A { " +
        member_attrs +
        body +
        " };"
      assert_eq(check_exposed_source(source), valid)
    }
  }
}

///|
test "Exposed inheritance validation checks subset direction" {
  let globals = "[Exposed=*, Global=Window] interface W {}; [Exposed=*, Global=Worker] interface G {};"
  for
    (parent_attrs, child_attrs, valid) in [
      ("[Exposed=(Window,Worker)]", "[Exposed=Window]", true),
      ("[Exposed=Window]", "[Exposed=Window]", true),
      ("[Exposed=*]", "[Exposed=Window]", true),
      ("[Exposed=*]", "[Exposed=*]", true),
      ("[Exposed=Window]", "[Exposed=(Window,Worker)]", false),
      ("[Exposed=Window]", "[Exposed=Worker]", false),
      ("[Exposed=Window]", "[Exposed=*]", false),
    ] {
    let source = globals +
      child_attrs +
      " interface Child : Parent {}; " +
      parent_attrs +
      " interface Parent {};"
    assert_eq(check_exposed_source(source), valid)
  }
}

///|
test "Exposed partial annotations validate global names and duplicates" {
  let globals = "[Exposed=*, Global=Window] interface W {};"
  for
    (attrs, valid) in [
      ("[Exposed=Window]", true),
      ("[Exposed=*]", true),
      ("[Exposed=Unknown]", false),
      ("[Exposed=(Window,Window)]", false),
    ] {
    assert_eq(
      check_exposed_source(
        globals +
        "[Exposed=*] interface A {}; " +
        attrs +
        " partial interface A { undefined f(); };",
      ),
      valid,
    )
    assert_eq(
      check_exposed_source(
        globals +
        "[Exposed=*] interface A {}; partial interface A { " +
        attrs +
        " undefined f(); };",
      ),
      valid,
    )
  }
}

///|
test "Exposed partial and member annotations are mutually exclusive" {
  let globals = "[Exposed=*, Global=Window] interface W {}; [Exposed=*, Global=Worker] interface G {};"
  let annotations = [
    "", "[Exposed=Window]", "[Exposed=(Window,Worker)]", "[Exposed=*]",
  ]
  for
    body in [
      "undefined f();", "readonly attribute boolean value;", "const long value = 1;",
      "static undefined f();",
    ] {
    for partial_attrs in annotations {
      for member_attrs in annotations {
        // The partial can precede the original interface.
        let source = globals +
          partial_attrs +
          " partial interface A { " +
          member_attrs +
          body +
          " }; [Exposed=*] interface A {};"
        assert_eq(
          check_exposed_source(source),
          partial_attrs == "" || member_attrs == "",
        )
      }
    }
  }
  assert_false(
    check_exposed_source(
      globals +
      "[Exposed=*] interface A {}; [Exposed=Window] partial interface A { [Exposed=Worker] undefined f(); };",
    ),
  )
}

///|
test "Exposed partial annotation is local to that partial" {
  assert_true(
    check_exposed_source(
      "[Exposed=*, Global=Window] interface W {}; [Exposed=*] interface A { [Exposed=Window] undefined original(); }; [Exposed=Window] partial interface A { undefined first(); }; partial interface A { [Exposed=Window] undefined second(); };",
    ),
  )
}
