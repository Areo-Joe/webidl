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
test "Mixin Exposed identifiers must be unique global names in every declaration part" {
  let globals = "[Exposed=*, Global=(_Window,Worker)] interface G {};"
  for
    (attribute, expected) in [
      ("", true),
      ("[Exposed=*]", true),
      ("[Exposed=Window]", true),
      ("[Exposed=_Window]", true),
      ("[Exposed=(Window,_Worker)]", true),
      ("[Exposed=Missing]", false),
      ("[Exposed=G]", false),
      ("[Exposed=(Window,Missing)]", false),
      ("[Exposed=(Window,Window)]", false),
      ("[Exposed=(Window,_Window)]", false),
      ("[Exposed()]", true),
      ("[Exposed]", true),
    ] {
    for
      source in [
        attribute + " interface mixin M {};",
        "interface mixin M {}; " + attribute + " partial interface mixin M {};",
        attribute + " partial interface mixin M {}; interface mixin M {};",
      ] {
      assert_eq(check_exposed_source(globals + source), expected)
    }
    for
      member_ in [
        "const long value = 1;", "attribute long value;", "undefined run();", "stringifier;",
      ] {
      let body = " { " + attribute + member_ + " };"
      assert_eq(
        check_exposed_source(globals + "interface mixin M" + body),
        expected,
      )
      assert_eq(
        check_exposed_source(
          globals + "interface mixin M {}; partial interface mixin M" + body,
        ),
        expected,
      )
      assert_eq(
        check_exposed_source(
          globals + "partial interface mixin M" + body + "interface mixin M {};",
        ),
        expected,
      )
    }
  }
}

///|
test "Mixin Exposed names are checked without includes and against all global interfaces" {
  assert_false(check_exposed_source("[Exposed=Window] interface mixin M {};"))
  assert_true(check_exposed_source("[Exposed=*] interface mixin M {};"))
  assert_true(
    check_exposed_source(
      "[Exposed=(Window,Worker)] interface mixin M {}; [Exposed=*, Global=Window] interface W {}; [Exposed=*, Global=Worker] interface G {};",
    ),
  )
}

///|
test "Exposed partial mixin members must not duplicate their containing partial annotation" {
  let globals = "[Exposed=*, Global=(Window,Worker)] interface G {};"
  for
    member_ in [
      "const long value = 1;", "attribute long value;", "undefined run();", "stringifier;",
    ] {
    for
      (partial_attribute, member_attribute, expected) in [
        ("", "", true),
        ("[Exposed=*]", "", true),
        ("", "[Exposed=*]", true),
        ("[Exposed=*]", "[Exposed=*]", false),
        ("[Exposed=Window]", "[Exposed=Worker]", false),
        ("[Exposed=(Window,Worker)]", "[Exposed=Window]", false),
        ("[Exposed()]", "[Exposed=*]", true),
        ("[Exposed=*]", "[Exposed()]", true),
      ] {
      let partial = partial_attribute +
        " partial interface mixin M { " +
        member_attribute +
        member_ +
        " };"
      let original = "interface mixin M {};"
      assert_eq(check_exposed_source(globals + original + partial), expected)
      assert_eq(check_exposed_source(globals + partial + original), expected)
    }
  }
}

///|
test "Exposed partial mixin duplicate checks only apply to members declared in that partial" {
  for
    source in [
      "[Exposed=*] interface mixin M { [Exposed=*] undefined run(); };", "[Exposed=*] interface mixin M {}; partial interface mixin M { [Exposed=*] undefined run(); };",
      "interface mixin M { [Exposed=*] undefined first(); }; [Exposed=*] partial interface mixin M { undefined second(); }; partial interface mixin M { [Exposed=*] undefined third(); };",
      "interface mixin M {}; [Exposed=*] partial interface mixin M {};", "interface mixin M {}; [Exposed=*] partial interface mixin M { undefined first(); }; interface mixin N { [Exposed=*] undefined second(); };",
    ] {
    assert_true(check_exposed_source(source))
  }
}

///|
test "Mixin Exposed must appear identically on every overload" {
  let globals = "[Exposed=*, Global=(Window,Worker)] interface G {};"
  for
    (first, second, expected) in [
      ("", "", true),
      ("[Exposed=*]", "", false),
      ("", "[Exposed=*]", false),
      ("[Exposed=*]", "[Exposed=*]", true),
      ("[Exposed=Window]", "[Exposed=Window]", true),
      ("[Exposed=_Window]", "[Exposed=Window]", true),
      ("[Exposed=Window]", "[Exposed=Worker]", false),
      ("[Exposed=Window]", "[Exposed=(Window)]", false),
      ("[Exposed=(Window,Worker)]", "[Exposed=(Window,Worker)]", true),
      ("[Exposed=(Window,Worker)]", "[Exposed=(_Window,Worker)]", true),
      ("[Exposed=(Window,Worker)]", "[Exposed=(Worker,Window)]", false),
      ("[Exposed=*]", "[Exposed=(Window,Worker)]", false),
      ("[Exposed()]", "", true),
      ("[Exposed=*]", "[Exposed()]", false),
    ] {
    let members = first +
      " undefined run(long value); " +
      second +
      " undefined _run(DOMString value);"
    for
      source in [
        "interface mixin M { " + members + " };",
        "interface mixin M {}; partial interface mixin M { " + members + " };",
        "partial interface mixin M { " + members + " }; interface mixin M {};",
      ] {
      assert_eq(check_exposed_source(globals + source), expected)
    }
  }
}

///|
test "Mixin Exposed overload groups use explicit member annotations and remain independent" {
  for
    (source, expected) in [
      (
        "[Exposed=*] interface mixin M { [Exposed=*] undefined run(long value); undefined run(DOMString value); };",
        false,
      ),
      (
        "[Exposed=*] interface mixin M { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "interface mixin M {}; [Exposed=*] partial interface mixin M { [Exposed=*] undefined run(long value); undefined run(DOMString value); };",
        false,
      ),
      (
        "interface mixin M {}; [Exposed=*] partial interface mixin M { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "interface mixin M { [Exposed=*] undefined first(); undefined second(); };",
        true,
      ),
      (
        "interface mixin M { [Exposed=*] attribute long value; undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "interface mixin M { [Exposed=*] undefined run(); }; interface mixin N { undefined run(); };",
        true,
      ),
      (
        "[Exposed=*] interface A {}; interface mixin M { [Exposed=*] undefined run(long value); undefined run(DOMString value); }; A includes M;",
        false,
      ),
      (
        "interface mixin M { [Exposed=*] undefined run(long value); }; partial interface mixin M { undefined run(DOMString value); };",
        false,
      ),
      (
        "interface mixin M {}; partial interface mixin M { undefined run(long value); }; partial interface mixin M { [Exposed=*] undefined run(DOMString value); };",
        false,
      ),
    ] {
    assert_eq(check_exposed_source(source), expected)
  }
}

///|
test "Exposed must appear identically on every overload" {
  let globals = "[Exposed=*, Global=(Window,Worker)] interface G {};"
  for
    (first, second, expected) in [
      ("", "", true),
      ("[Exposed=*]", "", false),
      ("", "[Exposed=*]", false),
      ("[Exposed=*]", "[Exposed=*]", true),
      ("[Exposed=Window]", "[Exposed=Window]", true),
      ("[Exposed=_Window]", "[Exposed=Window]", true),
      ("[Exposed=Window]", "[Exposed=Worker]", false),
      ("[Exposed=Window]", "[Exposed=(Window)]", false),
      ("[Exposed=(Window,Worker)]", "[Exposed=(Window,Worker)]", true),
      ("[Exposed=(Window,Worker)]", "[Exposed=(_Window,Worker)]", true),
      ("[Exposed=(Window,Worker)]", "[Exposed=(Worker,Window)]", false),
      ("[Exposed=*]", "[Exposed=(Window,Worker)]", false),
      ("[Exposed()]", "", true),
      ("[Exposed=*]", "[Exposed()]", false),
    ] {
    for prefix in ["", "static "] {
      let members = first +
        " " +
        prefix +
        "undefined run(long value); " +
        second +
        " " +
        prefix +
        "undefined run(DOMString value);"
      assert_eq(
        check_exposed_source(
          globals + "[Exposed=*] interface A { " + members + " };",
        ),
        expected,
      )
      assert_eq(
        check_exposed_source(
          globals +
          "[Exposed=*] interface A {}; partial interface A { " +
          members +
          " };",
        ),
        expected,
      )
    }
    assert_eq(
      check_exposed_source(
        globals +
        "[Exposed=*] interface A { " +
        first +
        " constructor(long value); " +
        second +
        " constructor(DOMString value); };",
      ),
      expected,
    )
  }
}

///|
test "Exposed overload groups distinguish static names inheritance and unnamed operations" {
  for
    (source, expected) in [
      (
        "[Exposed=*] interface A { [Exposed=*] undefined run(long value); static undefined run(DOMString value); };",
        true,
      ),
      (
        "[Exposed=*] interface A { [Exposed=*] undefined first(); undefined second(); };",
        true,
      ),
      (
        "[Exposed=*] interface A { [Exposed=*] getter any (DOMString key); any lookup(long key); };",
        true,
      ),
      (
        "[Exposed=*] interface A { [Exposed=*] getter any lookup(DOMString key); any lookup(long key); };",
        false,
      ),
      (
        "[Exposed=*] interface Parent { [Exposed=*] undefined run(long value); }; [Exposed=*] interface A : Parent { undefined run(DOMString value); };",
        true,
      ),
      (
        "[Exposed=*] interface A { [Exposed=*] undefined run(long value); }; partial interface A { undefined run(DOMString value); };",
        false,
      ),
      (
        "[Exposed=*] interface A {}; partial interface A { [Exposed=*] undefined run(long value); }; partial interface A { undefined run(DOMString value); };",
        false,
      ),
      (
        "[Exposed=*] interface A {}; [Exposed=*] partial interface A { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
    ] {
    assert_eq(check_exposed_source(source), expected)
  }
}

///|
test "Interfaces require a recognized Exposed attribute on their original definition" {
  for
    (source, expected) in [
      ("interface A {};", false),
      ("[SecureContext] interface A {};", false),
      ("[Exposed] interface A {};", false),
      ("[Exposed()] interface A {};", false),
      ("[Exposed=Window()] interface A {};", false),
      ("[Exposed=\"Window\"] interface A {};", false),
      ("[exposed=*] interface A {};", false),
      ("[Exposed=*] interface A {};", true),
      (
        "[Exposed=Window] interface A {}; [Exposed=*, Global=Window] interface W {};",
        true,
      ),
      (
        "[Exposed=(Window,Worker)] interface A {}; [Exposed=*, Global=(Window,Worker)] interface W {};",
        true,
      ),
      ("[Exposed=*] interface A {}; interface B {};", false),
      ("[Exposed=*] interface A {}; interface B : A {};", false),
    ] {
    assert_eq(check_exposed_source(source), expected)
  }
}

///|
test "Partial and member Exposed annotations cannot replace the original interface annotation" {
  for
    (original, expected) in [
      ("interface A {};", false),
      ("[Exposed()] interface A {};", false),
      ("[Exposed=*] interface A {};", true),
    ] {
    let partial = "[Exposed=*] partial interface A { undefined run(); };"
    assert_eq(check_exposed_source(original + partial), expected)
    assert_eq(check_exposed_source(partial + original), expected)
  }
  assert_false(
    check_exposed_source("interface A { [Exposed=*] undefined run(); };"),
  )
  assert_true(
    check_exposed_source(
      "[Exposed=*] interface A {}; partial interface A { undefined run(); };",
    ),
  )
}

///|
test "Interface Exposed requirement does not apply to interface mixins or callback interfaces" {
  assert_true(
    check_exposed_source(
      "interface mixin M {}; partial interface mixin M { undefined run(); };",
    ),
  )
  assert_true(
    check_exposed_source("callback interface C { undefined run(); };"),
  )
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
  assert_false(check_exposed_source("interface A {};"))
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

///|
test "Exposed partial own exposure set must be a subset of the original interface" {
  let globals = "[Exposed=*, Global=Window] interface W {}; [Exposed=*, Global=Worker] interface G {};"
  for
    (interface_attrs, partial_attrs, valid) in [
      ("[Exposed=(Window,Worker)]", "[Exposed=Window]", true),
      ("[Exposed=(Window,Worker)]", "[Exposed=(Worker,Window)]", true),
      ("[Exposed=Window]", "[Exposed=_Window]", true),
      ("[Exposed=*]", "[Exposed=Worker]", true),
      ("[Exposed=*]", "[Exposed=*]", true),
      ("[Exposed=Window]", "[Exposed=Worker]", false),
      ("[Exposed=Window]", "[Exposed=(Window,Worker)]", false),
      ("[Exposed=Window]", "[Exposed=*]", false),
      ("[Exposed=Window]", "", true),
      ("[Exposed=*]", "", true),
    ] {
    for body in ["", "undefined f();"] {
      for partial_first in [true, false] {
        let original = interface_attrs + " interface A {};"
        let partial = partial_attrs + " partial interface A { " + body + " };"
        let source = if partial_first {
          globals + partial + original
        } else {
          globals + original + partial
        }
        assert_eq(check_exposed_source(source), valid)
      }
    }
  }
}

///|
test "Exposed partial subset validation checks every partial against its own original" {
  let globals = "[Exposed=*, Global=Window] interface W {}; [Exposed=*, Global=Worker] interface G {};"
  let originals = "[Exposed=Window] interface A {}; [Exposed=Worker] interface B {};"
  let valid_partials = "[Exposed=Window] partial interface A {}; partial interface A {}; [Exposed=Worker] partial interface B {};"
  assert_true(check_exposed_source(globals + valid_partials + originals))
  assert_false(
    check_exposed_source(
      globals +
      valid_partials +
      "[Exposed=Worker] partial interface A {};" +
      originals,
    ),
  )
}

///|
test "Exposed partial member validation checks original interface subsets" {
  let globals = "[Exposed=*, Global=Window] interface W {}; [Exposed=*, Global=Worker] interface G {};"
  for
    body in [
      "undefined f();", "readonly attribute boolean value;", "const long value = 1;",
      "static undefined f();",
    ] {
    for
      (interface_attrs, member_attrs, valid) in [
        ("[Exposed=(Window,Worker)]", "[Exposed=Window]", true),
        ("[Exposed=(Window,Worker)]", "[Exposed=(Worker,Window)]", true),
        ("[Exposed=Window]", "[Exposed=_Window]", true),
        ("[Exposed=*]", "[Exposed=Worker]", true),
        ("[Exposed=*]", "[Exposed=*]", true),
        ("[Exposed=Window]", "[Exposed=Worker]", false),
        ("[Exposed=Window]", "[Exposed=(Window,Worker)]", false),
        ("[Exposed=Window]", "[Exposed=*]", false),
        ("[Exposed=Window]", "", true),
      ] {
      for partial_first in [true, false] {
        let original = interface_attrs + " interface A {};"
        let partial = "partial interface A { " + member_attrs + body + " };"
        let source = if partial_first {
          globals + partial + original
        } else {
          globals + original + partial
        }
        assert_eq(check_exposed_source(source), valid)
      }
    }
  }
}

///|
test "Exposed partial member subset validation checks every member and partial" {
  let globals = "[Exposed=*, Global=Window] interface W {}; [Exposed=*, Global=Worker] interface G {};"
  let originals = "[Exposed=Window] interface A {}; [Exposed=Worker] interface B {};"
  let valid_partials = "partial interface A { [Exposed=Window] undefined first(); }; partial interface B { [Exposed=Worker] undefined first(); };"
  assert_true(check_exposed_source(globals + valid_partials + originals))
  assert_false(
    check_exposed_source(
      globals +
      valid_partials +
      originals +
      "partial interface A { [Exposed=Window] undefined second(); [Exposed=Worker] undefined third(); };",
    ),
  )
}
