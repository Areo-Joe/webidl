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
