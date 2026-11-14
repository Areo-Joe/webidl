///|
fn check_secure_context_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "SecureContext mixin members cannot be conditionally exposed on CrossOriginIsolated" {
  for
    member_ in [
      "const long value = 1;", "attribute long value;", "undefined run();", "stringifier;",
    ] {
    for
      (original_attribute, partial_attribute, member_attribute, expected) in [
        ("", "", "[SecureContext]", true),
        ("", "", "[SecureContext,CrossOriginIsolated]", false),
        ("[CrossOriginIsolated]", "", "[SecureContext]", false),
        ("", "[CrossOriginIsolated]", "[SecureContext]", false),
        ("[CrossOriginIsolated()]", "", "[SecureContext]", true),
        ("", "[CrossOriginIsolated=Name]", "[SecureContext]", true),
        ("[CrossOriginIsolated]", "", "[SecureContext()]", true),
      ] {
      let original = original_attribute + " interface mixin M {};"
      let partial = partial_attribute +
        " partial interface mixin M { " +
        member_attribute +
        member_ +
        " };"
      assert_eq(check_secure_context_source(original + partial), expected)
      assert_eq(check_secure_context_source(partial + original), expected)
      if partial_attribute == "" {
        assert_eq(
          check_secure_context_source(
            original_attribute +
            " interface mixin M { " +
            member_attribute +
            member_ +
            " };",
          ),
          expected,
        )
      }
    }
  }
}

///|
test "SecureContext mixin member conditional exposure accounts for every direct host" {
  for
    members in [
      "interface mixin M { [SecureContext] undefined run(); };", "interface mixin M {}; partial interface mixin M { [SecureContext] undefined run(); };",
    ] {
    for
      (hosts, expected) in [
        ("[Exposed=*] interface A {}; A includes M;", true),
        ("[Exposed=*,CrossOriginIsolated] interface A {}; A includes M;", false),
        (
          "[Exposed=*] interface A {}; [Exposed=*,CrossOriginIsolated] interface B {}; A includes M; B includes M;",
          false,
        ),
        (
          "[Exposed=*] interface A {}; [Exposed=*,CrossOriginIsolated] interface B {}; A includes M;",
          true,
        ),
        (
          "[Exposed=*,CrossOriginIsolated()] interface A {}; A includes M;", true,
        ),
        (
          "[Exposed=*,CrossOriginIsolated] interface _A {}; _A includes _M;", false,
        ),
        (
          "[Exposed=*] interface A {}; [CrossOriginIsolated] partial interface A {}; A includes M;",
          true,
        ),
        (
          "[Exposed=*] interface A {}; [Exposed=*,CrossOriginIsolated] interface B : A {}; A includes M;",
          true,
        ),
      ] {
      assert_eq(check_secure_context_source(members + hosts), expected)
      assert_eq(check_secure_context_source(hosts + members), expected)
    }
  }
}

///|
test "SecureContext conditional exposure does not turn container annotations into member annotations" {
  for
    source in [
      "[SecureContext,CrossOriginIsolated] interface mixin M { undefined run(); };",
      "interface mixin M {}; [SecureContext,CrossOriginIsolated] partial interface mixin M { undefined run(); };",
      "[Exposed=*,CrossOriginIsolated] interface A {}; [SecureContext] interface mixin M { undefined run(); }; A includes M;",
      "[Exposed=*,CrossOriginIsolated] interface A {}; interface mixin M {}; [SecureContext] partial interface mixin M { undefined run(); }; A includes M;",
      "interface mixin M { [SecureContext] undefined first(); }; [CrossOriginIsolated] partial interface mixin M { undefined second(); }; partial interface mixin M { [SecureContext] undefined third(); };",
    ] {
    assert_true(check_secure_context_source(source))
  }
}

///|
test "SecureContext mixin members must not duplicate their containing definition annotation" {
  for
    member_ in [
      "const long value = 1;", "attribute long value;", "undefined run();", "stringifier;",
    ] {
    for
      (container_attribute, member_attribute, expected) in [
        ("", "", true),
        ("[SecureContext]", "", true),
        ("", "[SecureContext]", true),
        ("[SecureContext]", "[SecureContext]", false),
        ("[SecureContext()]", "[SecureContext]", true),
        ("[SecureContext]", "[SecureContext=Name]", true),
      ] {
      let body = " { " + member_attribute + member_ + " };"
      assert_eq(
        check_secure_context_source(
          container_attribute + " interface mixin M" + body,
        ),
        expected,
      )
      let original = "interface mixin M {};"
      let partial = container_attribute + " partial interface mixin M" + body
      assert_eq(check_secure_context_source(original + partial), expected)
      assert_eq(check_secure_context_source(partial + original), expected)
      assert_eq(
        check_secure_context_source(
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
test "SecureContext partial mixin annotations only constrain their own members" {
  for
    source in [
      "interface mixin M { [SecureContext] undefined original(); }; [SecureContext] partial interface mixin M { undefined first(); }; partial interface mixin M { [SecureContext] undefined second(); };",
      "[SecureContext] interface mixin M {}; [SecureContext] partial interface mixin M { undefined run(); };",
      "[Exposed=*, SecureContext] interface A {}; interface mixin M { [SecureContext] undefined run(); }; A includes M;",
      "[SecureContext] interface mixin M {}; interface mixin N { [SecureContext] undefined run(); };",
    ] {
    assert_true(check_secure_context_source(source))
  }
}

///|
test "SecureContext requires consistent marking on mixin operation overloads" {
  for
    (members, expected) in [
      ("undefined run(long value); undefined run(DOMString value);", true),
      (
        "[SecureContext] undefined run(long value); undefined run(DOMString value);",
        false,
      ),
      (
        "undefined run(long value); [SecureContext] undefined run(DOMString value);",
        false,
      ),
      (
        "[SecureContext] undefined run(long value); [SecureContext] undefined _run(DOMString value);",
        true,
      ),
      ("[SecureContext] undefined first(); undefined second();", true),
      (
        "[SecureContext] undefined run(optional long value); undefined run(DOMString first, long... rest);",
        false,
      ),
      (
        "[SecureContext()] undefined run(long value); undefined run(DOMString value);",
        true,
      ),
      (
        "[SecureContext] undefined run(long value); [SecureContext()] undefined run(DOMString value);",
        false,
      ),
      (
        "[SecureContext=Name] undefined run(long value); undefined run(DOMString value);",
        true,
      ),
      (
        "[SecureContext] attribute long value; undefined run(long value); undefined run(DOMString value);",
        true,
      ),
      (
        "[SecureContext] undefined run(long value); [CrossOriginIsolated] undefined run(DOMString value);",
        false,
      ),
    ] {
    let original = "interface mixin M {};"
    let partial = "partial interface mixin M { " + members + " };"
    assert_eq(
      check_secure_context_source("interface mixin M { " + members + " };"),
      expected,
    )
    assert_eq(check_secure_context_source(original + partial), expected)
    assert_eq(check_secure_context_source(partial + original), expected)
  }
}

///|
test "SecureContext mixin overload groups use explicit annotations independently of containers and hosts" {
  for
    (source, expected) in [
      (
        "[SecureContext] interface mixin M { [SecureContext] undefined run(long value); undefined run(DOMString value); };",
        false,
      ),
      (
        "[SecureContext] interface mixin M { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "interface mixin M {}; [SecureContext] partial interface mixin M { [SecureContext] undefined run(long value); undefined run(DOMString value); };",
        false,
      ),
      (
        "interface mixin M {}; [SecureContext] partial interface mixin M { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "interface mixin M { [SecureContext] undefined run(); }; interface mixin N { undefined run(); };",
        true,
      ),
      (
        "[Exposed=*, SecureContext] interface A {}; interface mixin M { [SecureContext] undefined run(long value); undefined run(DOMString value); }; A includes M;",
        false,
      ),
      (
        "interface mixin M { [SecureContext] undefined run(long value); }; partial interface mixin M { undefined run(DOMString value); };",
        false,
      ),
      (
        "interface mixin M {}; partial interface mixin M { undefined run(long value); }; partial interface mixin M { [SecureContext] undefined run(DOMString value); };",
        false,
      ),
    ] {
    assert_eq(check_secure_context_source(source), expected)
  }
}

///|
test "SecureContext recognizes only the no-arguments form" {
  for
    (source, expected) in [
      ("[SecureContext]", true),
      ("[SecureContext()]", false),
      ("[SecureContext=Name]", false),
      ("[SecureContext=(First,Second)]", false),
      ("[SecureContext=Name()]", false),
      ("[SecureContext=*]", false),
      ("[SecureContext=\"Name\"]", false),
      ("[SecureContext=1]", false),
      ("[SecureContext=1.5]", false),
      ("[SecureContext=(1,2)]", false),
      ("[Other]", false),
      ("[secureContext]", false),
    ] {
    let (attrs, rest) = @parser.ExtendedAttributeList::parse(
      @lexer.tokenize(source).exact_view(),
    )
    assert_true(rest is [])
    assert_eq(attrs.iter().count(), 1)
    assert_eq(attrs.iter().any(is_valid_secure_context), expected)
  }
}

///|
test "SecureContext cannot mark both an interface and any of its members" {
  for
    member_ in [
      "attribute long value;", "readonly attribute long value;", "const long VALUE = 1;",
      "undefined run();", "static undefined run();", "constructor();", "getter any (DOMString key);",
    ] {
    assert_false(
      check_secure_context_source(
        "[Exposed=*, SecureContext] interface A { [SecureContext] " +
        member_ +
        " };",
      ),
    )
    assert_true(
      check_secure_context_source(
        "[Exposed=*] interface A { [SecureContext] " + member_ + " };",
      ),
    )
    assert_true(
      check_secure_context_source(
        "[Exposed=*, SecureContext] interface A { " + member_ + " };",
      ),
    )
  }
}

///|
test "SecureContext duplicate marking uses the member's partial and original interface" {
  for
    (source, expected) in [
      (
        "[Exposed=*, SecureContext] interface A {}; partial interface A { [SecureContext] undefined run(); };",
        false,
      ),
      (
        "[Exposed=*] interface A {}; [SecureContext] partial interface A { [SecureContext] undefined run(); };",
        false,
      ),
      (
        "[Exposed=*] interface A {}; [SecureContext] partial interface A { undefined run(); };",
        true,
      ),
      (
        "[Exposed=*, SecureContext] interface A {}; [SecureContext] partial interface A { undefined run(); };",
        true,
      ),
      (
        "[Exposed=*] interface A { [SecureContext] undefined run(); }; [SecureContext] partial interface A { undefined other(); };",
        true,
      ),
      (
        "[Exposed=*] interface A {}; [SecureContext] partial interface A { undefined first(); }; partial interface A { [SecureContext] undefined second(); };",
        true,
      ),
      (
        "partial interface A { [SecureContext] undefined run(); }; [Exposed=*, SecureContext] interface A {};",
        false,
      ),
    ] {
    assert_eq(check_secure_context_source(source), expected)
  }
}

///|
test "SecureContext inheritance is determined by original interface annotations" {
  for
    (source, expected) in [
      (
        "[Exposed=*, SecureContext] interface A {}; [Exposed=*] interface B : A {};",
        false,
      ),
      (
        "[Exposed=*, SecureContext] interface A {}; [Exposed=*, SecureContext] interface B : A {};",
        true,
      ),
      (
        "[Exposed=*] interface A {}; [Exposed=*, SecureContext] interface B : A {};",
        true,
      ),
      ("[Exposed=*] interface A {}; [Exposed=*] interface B : A {};", true),
      (
        "[Exposed=*, SecureContext] interface A {}; [Exposed=*, SecureContext] interface B : A {}; [Exposed=*] interface C : B {};",
        false,
      ),
      (
        "[Exposed=*, SecureContext] interface A {}; [Exposed=*, SecureContext] interface B : A {}; [Exposed=*, SecureContext] interface C : B {};",
        true,
      ),
      (
        "[Exposed=*] interface B : _A {}; [Exposed=*, SecureContext] interface A {};",
        false,
      ),
      (
        "[Exposed=*] interface A {}; [SecureContext] partial interface A { undefined run(); }; [Exposed=*] interface B : A {};",
        true,
      ),
      (
        "[Exposed=*, SecureContext] interface A {}; [Exposed=*] interface B : A {}; [SecureContext] partial interface B {};",
        false,
      ),
    ] {
    assert_eq(check_secure_context_source(source), expected)
  }
}

///|
test "SecureContext cannot annotate constructs conditionally exposed on CrossOriginIsolated" {
  for
    (source, expected) in [
      ("[Exposed=*, SecureContext, CrossOriginIsolated] interface A {};", false),
      (
        "[Exposed=*] interface A { [CrossOriginIsolated, SecureContext] undefined run(); };",
        false,
      ),
      (
        "[Exposed=*, CrossOriginIsolated] interface A { [SecureContext] undefined run(); };",
        false,
      ),
      (
        "[Exposed=*, CrossOriginIsolated] interface A {}; partial interface A { [SecureContext] undefined run(); };",
        false,
      ),
      (
        "[Exposed=*, CrossOriginIsolated] interface A {}; [SecureContext] partial interface A {};",
        true,
      ),
      (
        "[Exposed=*] interface A {}; [CrossOriginIsolated, SecureContext] partial interface A {};",
        true,
      ),
      (
        "[Exposed=*, CrossOriginIsolated] interface A {}; [SecureContext] partial interface A { undefined run(); };",
        true,
      ),
      (
        "[Exposed=*] interface A {}; [CrossOriginIsolated, SecureContext] partial interface A { undefined run(); };",
        true,
      ),
      (
        "[Exposed=*] interface A {}; [CrossOriginIsolated] partial interface A { [SecureContext] undefined run(); };",
        false,
      ),
      (
        "[Exposed=*] interface A {}; partial interface A { [CrossOriginIsolated, SecureContext] undefined run(); };",
        false,
      ),
      (
        "[Exposed=*, SecureContext] interface A { [CrossOriginIsolated] undefined run(); };",
        true,
      ),
      (
        "[Exposed=*, SecureContext] interface A {}; [CrossOriginIsolated] partial interface A { undefined run(); };",
        true,
      ),
      (
        "[Exposed=*] interface A { [SecureContext] undefined run(); }; [CrossOriginIsolated] partial interface A { undefined other(); };",
        true,
      ),
      (
        "[Exposed=*] interface A {}; [CrossOriginIsolated] partial interface A { undefined first(); }; [SecureContext] partial interface A { undefined second(); };",
        true,
      ),
      (
        "[Exposed=*] interface A {}; [SecureContext] partial interface A { [CrossOriginIsolated] undefined run(); };",
        true,
      ),
    ] {
    assert_eq(check_secure_context_source(source), expected)
  }
}

///|
test "SecureContext must mark every regular or static overload in its own group" {
  for
    (members, expected) in [
      ("undefined run(long value); undefined run(DOMString value);", true),
      (
        "[SecureContext] undefined run(long value); undefined run(DOMString value);",
        false,
      ),
      (
        "undefined run(long value); [SecureContext] undefined run(DOMString value);",
        false,
      ),
      (
        "[SecureContext] undefined run(long value); [SecureContext] undefined _run(DOMString value);",
        true,
      ),
      (
        "[SecureContext] static undefined run(long value); static undefined run(DOMString value);",
        false,
      ),
      (
        "[SecureContext] static undefined run(long value); [SecureContext] static undefined run(DOMString value);",
        true,
      ),
      (
        "[SecureContext] undefined run(long value); static undefined run(DOMString value);",
        true,
      ),
      (
        "undefined run(long value); [SecureContext] static undefined run(DOMString value);",
        true,
      ),
      ("[SecureContext] undefined first(); undefined second();", true),
      (
        "[SecureContext] undefined run(optional long value); undefined run(DOMString first, long... rest);",
        false,
      ),
    ] {
    assert_eq(
      check_secure_context_source(
        "[Exposed=*] interface A { " + members + " };",
      ),
      expected,
    )
  }
}

///|
test "SecureContext overload checks include constructors and named special operations" {
  for
    (members, expected) in [
      (
        "[SecureContext] constructor(long value); constructor(DOMString value);",
        false,
      ),
      (
        "[SecureContext] constructor(long value); [SecureContext] constructor(DOMString value);",
        true,
      ),
      ("[SecureContext] constructor(); undefined run();", true),
      (
        "[SecureContext] getter any lookup(DOMString key); any lookup(long index);",
        false,
      ),
      (
        "[SecureContext] getter any lookup(DOMString key); [SecureContext] any lookup(long index);",
        true,
      ),
      (
        "[SecureContext] getter any (DOMString key); any lookup(long index);", true,
      ),
    ] {
    assert_eq(
      check_secure_context_source(
        "[Exposed=*] interface A { " + members + " };",
      ),
      expected,
    )
  }
}

///|
test "SecureContext overload checks cover partial declarations and exclude inherited operations" {
  for
    (source, expected) in [
      (
        "[Exposed=*] interface A {}; partial interface A { [SecureContext] undefined run(long value); undefined run(DOMString value); };",
        false,
      ),
      (
        "[Exposed=*] interface A {}; partial interface A { [SecureContext] undefined run(long value); [SecureContext] undefined run(DOMString value); };",
        true,
      ),
      (
        "[Exposed=*, SecureContext] interface A {}; partial interface A { undefined run(long value); undefined run(DOMString value); };",
        true,
      ),
      (
        "[Exposed=*] interface A { [SecureContext] undefined run(long value); }; partial interface A { undefined run(DOMString value); };",
        false,
      ),
      (
        "[Exposed=*] interface A {}; partial interface A { undefined run(long value); }; partial interface A { [SecureContext] undefined run(DOMString value); };",
        false,
      ),
      (
        "[Exposed=*] interface Parent { [SecureContext] undefined run(long value); }; [Exposed=*] interface Child : Parent { undefined run(DOMString value); };",
        true,
      ),
    ] {
    assert_eq(check_secure_context_source(source), expected)
  }
}

///|
test "SecureContext malformed forms do not participate in semantic checks" {
  for
    (source, expected) in [
      (
        "[Exposed=*, SecureContext] interface A { [SecureContext()] undefined run(); };",
        true,
      ),
      (
        "[Exposed=*, SecureContext()] interface A {}; [Exposed=*] interface B : A {};",
        true,
      ),
      (
        "[Exposed=*, SecureContext] interface A {}; [Exposed=*, SecureContext()] interface B : A {};",
        false,
      ),
      (
        "[Exposed=*, SecureContext=Name, CrossOriginIsolated] interface A {};", true,
      ),
      (
        "[Exposed=*, SecureContext, CrossOriginIsolated()] interface A {};", true,
      ),
      (
        "[Exposed=*] interface A {}; [CrossOriginIsolated()] partial interface A { [SecureContext] undefined run(); };",
        true,
      ),
      (
        "[Exposed=*] interface A { [SecureContext] undefined run(long value); [SecureContext()] undefined run(DOMString value); };",
        false,
      ),
    ] {
    assert_eq(check_secure_context_source(source), expected)
  }
}
