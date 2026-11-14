///|
test "CrossOriginIsolated mixin members must not duplicate their containing definition annotation" {
  for
    member_ in [
      "const long value = 1;", "attribute long value;", "undefined run();", "stringifier;",
    ] {
    for
      (container_attribute, member_attribute, expected) in [
        ("", "", true),
        ("[CrossOriginIsolated]", "", true),
        ("", "[CrossOriginIsolated]", true),
        ("[CrossOriginIsolated]", "[CrossOriginIsolated]", false),
        ("[CrossOriginIsolated()]", "[CrossOriginIsolated]", true),
        ("[CrossOriginIsolated]", "[CrossOriginIsolated=Name]", true),
      ] {
      let body = " { " + member_attribute + member_ + " };"
      assert_eq(
        check_cross_origin_isolated_source(
          container_attribute + " interface mixin M" + body,
        ),
        expected,
      )
      let original = "interface mixin M {};"
      let partial = container_attribute + " partial interface mixin M" + body
      assert_eq(
        check_cross_origin_isolated_source(original + partial),
        expected,
      )
      assert_eq(
        check_cross_origin_isolated_source(partial + original),
        expected,
      )
      assert_eq(
        check_cross_origin_isolated_source(
          container_attribute +
          " interface mixin M {}; partial interface mixin M" +
          body,
        ),
        expected,
      )
    }
  }
}

///|
test "CrossOriginIsolated partial mixin annotations do not affect other parts or including interfaces" {
  for
    source in [
      "interface mixin M { [CrossOriginIsolated] undefined original(); }; [CrossOriginIsolated] partial interface mixin M { undefined first(); }; partial interface mixin M { [CrossOriginIsolated] undefined second(); };",
      "[CrossOriginIsolated] interface mixin M {}; [CrossOriginIsolated] partial interface mixin M { undefined run(); };",
      "[Exposed=*, CrossOriginIsolated] interface A {}; interface mixin M { [CrossOriginIsolated] undefined run(); }; A includes M;",
      "[CrossOriginIsolated] interface mixin M {}; interface mixin N { [CrossOriginIsolated] undefined run(); };",
    ] {
    assert_true(check_cross_origin_isolated_source(source))
  }
}

///|
test "CrossOriginIsolated requires consistent marking on mixin operation overloads" {
  for
    (members, expected) in [
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
      ("[CrossOriginIsolated] undefined first(); undefined second();", true),
      (
        "[CrossOriginIsolated] undefined run(optional long value); undefined run(DOMString first, long... rest);",
        false,
      ),
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
        "[CrossOriginIsolated] attribute long value; undefined run(long value); undefined run(DOMString value);",
        true,
      ),
      (
        "[CrossOriginIsolated] undefined run(long value); [SecureContext] undefined run(DOMString value);",
        false,
      ),
    ] {
    assert_eq(
      check_cross_origin_isolated_source(
        "interface mixin M { " + members + " };",
      ),
      expected,
    )
    let original = "interface mixin M {};"
    let partial = "partial interface mixin M { " + members + " };"
    assert_eq(check_cross_origin_isolated_source(original + partial), expected)
    assert_eq(check_cross_origin_isolated_source(partial + original), expected)
  }
}

///|
test "CrossOriginIsolated mixin overload groups include every partial and use explicit member annotations" {
  for
    (source, expected) in [
      (
        "interface mixin M { [CrossOriginIsolated] undefined run(long value); }; partial interface mixin M { undefined run(DOMString value); };",
        false,
      ),
      (
        "partial interface mixin M { [CrossOriginIsolated] undefined run(long value); }; interface mixin M { undefined run(DOMString value); };",
        false,
      ),
      (
        "interface mixin M {}; partial interface mixin M { [CrossOriginIsolated] undefined run(long value); }; partial interface mixin M { undefined run(DOMString value); };",
        false,
      ),
      (
        "interface mixin M { [CrossOriginIsolated] undefined run(long value); }; partial interface mixin M { [CrossOriginIsolated] undefined run(DOMString value); };",
        true,
      ),
      (
        "[CrossOriginIsolated] interface mixin M { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "[CrossOriginIsolated] interface mixin M {}; partial interface mixin M { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "interface mixin M {}; [CrossOriginIsolated] partial interface mixin M { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "interface mixin M { undefined run(long value); }; [CrossOriginIsolated] partial interface mixin M { undefined run(DOMString value); };",
        true,
      ),
      (
        "interface mixin M { undefined first(); }; partial interface mixin M { [CrossOriginIsolated] undefined second(); };",
        true,
      ),
    ] {
    assert_eq(check_cross_origin_isolated_source(source), expected)
  }
}

///|
test "CrossOriginIsolated mixin overload groups are independent of other mixins and including interfaces" {
  let mixin_source = "interface mixin M { [CrossOriginIsolated] undefined run(long value); [CrossOriginIsolated] undefined run(DOMString value); };"
  assert_true(
    check_cross_origin_isolated_source(
      mixin_source +
      "[Exposed=*] interface A {}; [Exposed=*] interface B {}; A includes M; B includes M;",
    ),
  )
  assert_true(
    check_cross_origin_isolated_source(
      "interface mixin M { [CrossOriginIsolated] undefined run(); }; interface mixin N { undefined run(); }; [Exposed=*] interface A {}; [Exposed=*] interface B {}; A includes M; B includes N;",
    ),
  )
  assert_false(
    check_cross_origin_isolated_source(
      "[Exposed=*, CrossOriginIsolated] interface A {}; interface mixin M { [CrossOriginIsolated] undefined run(long value); undefined run(DOMString value); }; A includes M;",
    ),
  )
}

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
      check_cross_origin_isolated_source(
        "[Exposed=*] interface A { " + body + " };",
      ),
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
      check_cross_origin_isolated_source(
        "[Exposed=*] interface A { " + body + " };",
      ),
      expected,
    )
  }
}

///|
test "CrossOriginIsolated overload marking checks partials and excludes inherited operations" {
  for
    (source, expected) in [
      (
        "[Exposed=*] interface A {}; partial interface A { [CrossOriginIsolated] undefined run(long value); undefined run(DOMString value); };",
        false,
      ),
      (
        "[Exposed=*] interface A {}; partial interface A { [CrossOriginIsolated] undefined run(long value); [CrossOriginIsolated] undefined run(DOMString value); };",
        true,
      ),
      (
        "[Exposed=*, CrossOriginIsolated] interface A {}; partial interface A { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "[Exposed=*] interface A {}; [CrossOriginIsolated] partial interface A { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "[Exposed=*] interface A { [CrossOriginIsolated] undefined run(long value); }; partial interface A { undefined run(DOMString value); };",
        false,
      ),
      (
        "[Exposed=*] interface A {}; partial interface A { undefined run(long value); }; partial interface A { [CrossOriginIsolated] undefined run(DOMString value); };",
        false,
      ),
      (
        "[Exposed=*] interface Parent { [CrossOriginIsolated] undefined run(long value); }; [Exposed=*] interface Child : Parent { undefined run(DOMString value); };",
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
      check_cross_origin_isolated_source(
        "[Exposed=*] interface A { " + body + " };",
      ),
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
