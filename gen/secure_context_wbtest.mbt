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
