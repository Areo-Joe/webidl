///|
test "CrossOriginIsolated requires consistent marking in each operation overload group" {
  for
    (body, expected) in [
      ("undefined run(long value); undefined run(DOMString value);", true),
      (
        "[CrossOriginIsolated] undefined run(long value); undefined run(DOMString value);",
        false,
      ),
      (
        "undefined run(long value); [CrossOriginIsolated] undefined run(DOMString value);",
        false,
      ),
      (
        "[CrossOriginIsolated] undefined run(long value); [CrossOriginIsolated] undefined _run(DOMString value);",
        true,
      ),
      (
        "[CrossOriginIsolated] static undefined run(long value); static undefined run(DOMString value);",
        false,
      ),
      (
        "[CrossOriginIsolated] static undefined run(long value); [CrossOriginIsolated] static undefined run(DOMString value);",
        true,
      ),
      (
        "[CrossOriginIsolated] undefined run(long value); static undefined run(DOMString value);",
        true,
      ),
      (
        "undefined run(long value); [CrossOriginIsolated] static undefined run(DOMString value);",
        true,
      ),
      ("[CrossOriginIsolated] undefined first(); undefined second();", true),
      (
        "[CrossOriginIsolated] undefined run(optional long value); undefined run(DOMString first, long... rest);",
        false,
      ),
    ] {
    assert_eq(
      check_cross_origin_isolated_source("interface A { " + body + " };"),
      expected,
    )
  }
}

///|
test "CrossOriginIsolated overload marking includes constructors and named special operations" {
  for
    (body, expected) in [
      (
        "[CrossOriginIsolated] constructor(long value); constructor(DOMString value);",
        false,
      ),
      (
        "[CrossOriginIsolated] constructor(long value); [CrossOriginIsolated] constructor(DOMString value);",
        true,
      ),
      ("[CrossOriginIsolated] constructor(); undefined run();", true),
      (
        "[CrossOriginIsolated] getter any lookup(DOMString key); any lookup(long index);",
        false,
      ),
      (
        "[CrossOriginIsolated] getter any lookup(DOMString key); [CrossOriginIsolated] any lookup(long index);",
        true,
      ),
      (
        "[CrossOriginIsolated] getter any (DOMString key); any lookup(long index);",
        true,
      ),
    ] {
    assert_eq(
      check_cross_origin_isolated_source("interface A { " + body + " };"),
      expected,
    )
  }
}

///|
test "CrossOriginIsolated overload marking checks partials and excludes inherited operations" {
  for
    (source, expected) in [
      (
        "interface A {}; partial interface A { [CrossOriginIsolated] undefined run(long value); undefined run(DOMString value); };",
        false,
      ),
      (
        "interface A {}; partial interface A { [CrossOriginIsolated] undefined run(long value); [CrossOriginIsolated] undefined run(DOMString value); };",
        true,
      ),
      (
        "[CrossOriginIsolated] interface A {}; partial interface A { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "interface A {}; [CrossOriginIsolated] partial interface A { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "interface A { [CrossOriginIsolated] undefined run(long value); }; partial interface A { undefined run(DOMString value); };",
        false,
      ),
      (
        "interface A {}; partial interface A { undefined run(long value); }; partial interface A { [CrossOriginIsolated] undefined run(DOMString value); };",
        false,
      ),
      (
        "interface Parent { [CrossOriginIsolated] undefined run(long value); }; interface Child : Parent { undefined run(DOMString value); };",
        true,
      ),
    ] {
    assert_eq(check_cross_origin_isolated_source(source), expected)
  }
}

///|
test "CrossOriginIsolated overload marking ignores malformed forms and other attributes" {
  for
    (body, expected) in [
      (
        "[CrossOriginIsolated()] undefined run(long value); undefined run(DOMString value);",
        true,
      ),
      (
        "[CrossOriginIsolated] undefined run(long value); [CrossOriginIsolated()] undefined run(DOMString value);",
        false,
      ),
      (
        "[CrossOriginIsolated=Name] undefined run(long value); undefined run(DOMString value);",
        true,
      ),
      (
        "[CrossOriginIsolated] undefined run(long value); [SecureContext] undefined run(DOMString value);",
        false,
      ),
    ] {
    assert_eq(
      check_cross_origin_isolated_source("interface A { " + body + " };"),
      expected,
    )
  }
}

///|
fn check_cross_origin_isolated_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "CrossOriginIsolated interface and direct member combinations" {
  for
    body in [
      "undefined f();", "readonly attribute boolean value;", "const long value = 1;",
      "constructor();",
    ] {
    for interface_marked in [false, true] {
      for member_marked in [false, true] {
        let interface_attrs = if interface_marked {
          "[Exposed=*, CrossOriginIsolated]"
        } else {
          "[Exposed=*]"
        }
        let member_attrs = if member_marked {
          "[CrossOriginIsolated]"
        } else {
          ""
        }
        let source = interface_attrs +
          " interface A { " +
          member_attrs +
          body +
          " };"
        assert_eq(
          check_cross_origin_isolated_source(source),
          !(interface_marked && member_marked),
        )
      }
    }
  }
}

///|
test "CrossOriginIsolated interface partial and member combinations" {
  for
    body in [
      "undefined f();", "readonly attribute boolean value;", "const long value = 1;",
    ] {
    for interface_marked in [false, true] {
      for partial_marked in [false, true] {
        for member_marked in [false, true] {
          let interface_attrs = if interface_marked {
            "[Exposed=*, CrossOriginIsolated]"
          } else {
            "[Exposed=*]"
          }
          let partial_attrs = if partial_marked {
            "[CrossOriginIsolated]"
          } else {
            ""
          }
          let member_attrs = if member_marked {
            "[CrossOriginIsolated]"
          } else {
            ""
          }
          // A partial can precede its original definition.
          let source = partial_attrs +
            " partial interface A { " +
            member_attrs +
            body +
            " }; " +
            interface_attrs +
            " interface A {};"
          assert_eq(
            check_cross_origin_isolated_source(source),
            !(member_marked && (interface_marked || partial_marked)),
          )
        }
      }
    }
  }
}

///|
test "CrossOriginIsolated on one partial does not restrict other declarations" {
  assert_true(
    check_cross_origin_isolated_source(
      "[Exposed=*] interface A { [CrossOriginIsolated] undefined original(); }; [CrossOriginIsolated] partial interface A { undefined first(); }; partial interface A { [CrossOriginIsolated] undefined second(); };",
    ),
  )
}
