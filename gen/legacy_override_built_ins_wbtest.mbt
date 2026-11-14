///|
fn check_legacy_override_built_ins_source(source : String) -> Bool raise {
  let (definitions, rest) = @parser.parse(@lexer.tokenize(source).exact_view())
  assert_true(rest is [])
  try doc(definitions) catch {
    _ => false
  } noraise {
    _ => true
  }
}

///|
test "LegacyOverrideBuiltIns on an interface requires its own named getter" {
  for
    (members, expected) in [
      ("", false),
      ("getter any (DOMString key);", true),
      ("getter any lookup(DOMString key);", true),
      ("getter any (unsigned long index);", false),
      ("getter any (USVString key);", false),
      ("getter any (DOMString? key);", false),
      ("getter any ();", false),
      ("getter any (DOMString key, long extra);", false),
      ("getter any (optional DOMString key);", false),
      ("getter any (DOMString... keys);", false),
      ("any lookup(DOMString key);", false),
      ("static any lookup(DOMString key);", false),
      ("setter undefined (DOMString key, any value);", false),
    ] {
    assert_eq(
      check_legacy_override_built_ins_source(
        "[LegacyOverrideBuiltIns] interface A { " + members + " };",
      ),
      expected,
    )
  }
  assert_true(check_legacy_override_built_ins_source("interface A {};"))
  assert_false(
    check_legacy_override_built_ins_source(
      "interface Parent { getter any (DOMString key); }; [LegacyOverrideBuiltIns] interface Child : Parent {};",
    ),
  )
}

///|
test "LegacyOverrideBuiltIns on an interface includes getters in partial definitions" {
  for
    source in [
      "[LegacyOverrideBuiltIns] interface A {}; partial interface A { getter any (DOMString key); };",
      "partial interface A { getter any (DOMString key); }; [LegacyOverrideBuiltIns] interface A {};",
      "partial interface A { undefined run(); }; [LegacyOverrideBuiltIns] interface A {}; partial interface A { getter any (DOMString key); };",
    ] {
    assert_true(check_legacy_override_built_ins_source(source))
  }
  assert_false(
    check_legacy_override_built_ins_source(
      "[LegacyOverrideBuiltIns] interface A {}; partial interface A { getter any (unsigned long index); };",
    ),
  )
}

///|
test "LegacyOverrideBuiltIns on a partial requires the getter in that same partial" {
  for
    (source, expected) in [
      (
        "interface A {}; [LegacyOverrideBuiltIns] partial interface A { getter any (DOMString key); };",
        true,
      ),
      (
        "[LegacyOverrideBuiltIns] partial interface A { getter any (DOMString key); }; interface A {};",
        true,
      ),
      (
        "interface A {}; [LegacyOverrideBuiltIns] partial interface A {};", false,
      ),
      (
        "interface A { getter any (DOMString key); }; [LegacyOverrideBuiltIns] partial interface A {};",
        false,
      ),
      (
        "interface A {}; [LegacyOverrideBuiltIns] partial interface A {}; partial interface A { getter any (DOMString key); };",
        false,
      ),
      (
        "interface A {}; [LegacyOverrideBuiltIns] partial interface A { getter any (unsigned long index); };",
        false,
      ),
      (
        "[LegacyOverrideBuiltIns] interface A {}; [LegacyOverrideBuiltIns] partial interface A { getter any (DOMString key); };",
        true,
      ),
    ] {
    assert_eq(check_legacy_override_built_ins_source(source), expected)
  }
}

///|
test "Named getter checks resolve typedefs in interface and partial declarations" {
  let forms = [
    ("[LegacyOverrideBuiltIns] interface A { getter any (", " key); };"),
    (
      "[LegacyOverrideBuiltIns] interface A {}; partial interface A { getter any (",
      " key); };",
    ),
    (
      "interface A {}; [LegacyOverrideBuiltIns] partial interface A { getter any (",
      " key); };",
    ),
    (
      "interface A {}; [Global=Window] partial interface A { getter any (", " key); };",
    ),
  ]
  for (prefix, suffix) in forms {
    for
      (definition, type_, expected) in [
        ("typedef DOMString Key;", "Key", true),
        ("typedef DOMString _Key;", "_Key", true),
        ("typedef DOMString? Key;", "Key", false),
        ("typedef DOMString Key;", "Key?", false),
        ("typedef USVString Key;", "Key", false),
        ("typedef (DOMString or long) Key;", "Key", false),
        ("", "optional DOMString", false),
        ("", "DOMString...", false),
      ] {
      assert_eq(
        check_legacy_override_built_ins_source(
          definition + prefix + type_ + suffix,
        ),
        expected,
      )
    }
  }
}

///|
test "LegacyOverrideBuiltIns on a partial conflicts with Global on its interface" {
  for
    source in [
      "[Global=Window] interface A {}; [LegacyOverrideBuiltIns] partial interface A { getter any (DOMString key); };",
      "[LegacyOverrideBuiltIns] partial interface A { getter any (DOMString key); }; [Global=(Window,Worker)] interface A {};",
    ] {
    assert_false(check_legacy_override_built_ins_source(source))
  }
}

///|
test "Global interfaces cannot inherit LegacyOverrideBuiltIns applied through ancestor partials" {
  for
    ancestors in [
      "interface Parent {}; [LegacyOverrideBuiltIns] partial interface Parent { getter any (DOMString key); };",
      "interface Parent : Root {}; interface Root {}; [LegacyOverrideBuiltIns] partial interface Root { getter any (DOMString key); };",
    ] {
    let child = "[Global=Window] interface Child : Parent {};"
    assert_false(check_legacy_override_built_ins_source(child + ancestors))
    assert_false(check_legacy_override_built_ins_source(ancestors + child))
    assert_true(
      check_legacy_override_built_ins_source(
        "interface Child : Parent {};" + ancestors,
      ),
    )
  }
}

///|
test "LegacyOverrideBuiltIns leaves malformed forms unrecognized" {
  for
    source in [
      "[LegacyOverrideBuiltIns()] interface A {};", "[LegacyOverrideBuiltIns=Name] interface A {};",
      "interface A {}; [LegacyOverrideBuiltIns()] partial interface A {};", "[Global=Window] interface A {}; [LegacyOverrideBuiltIns()] partial interface A {};",
      "interface Parent {}; [LegacyOverrideBuiltIns()] partial interface Parent {}; [Global=Window] interface Child : Parent {};",
    ] {
    assert_true(check_legacy_override_built_ins_source(source))
  }
}
