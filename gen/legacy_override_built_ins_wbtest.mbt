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
        "[Exposed=*, LegacyOverrideBuiltIns] interface A { " + members + " };",
      ),
      expected,
    )
  }
  assert_true(
    check_legacy_override_built_ins_source("[Exposed=*] interface A {};"),
  )
  assert_false(
    check_legacy_override_built_ins_source(
      "[Exposed=*] interface Parent { getter any (DOMString key); }; [Exposed=*, LegacyOverrideBuiltIns] interface Child : Parent {};",
    ),
  )
}

///|
test "LegacyOverrideBuiltIns on an interface includes getters in partial definitions" {
  for
    source in [
      "[Exposed=*, LegacyOverrideBuiltIns] interface A {}; partial interface A { getter any (DOMString key); };",
      "partial interface A { getter any (DOMString key); }; [Exposed=*, LegacyOverrideBuiltIns] interface A {};",
      "partial interface A { undefined run(); }; [Exposed=*, LegacyOverrideBuiltIns] interface A {}; partial interface A { getter any (DOMString key); };",
    ] {
    assert_true(check_legacy_override_built_ins_source(source))
  }
  assert_false(
    check_legacy_override_built_ins_source(
      "[Exposed=*, LegacyOverrideBuiltIns] interface A {}; partial interface A { getter any (unsigned long index); };",
    ),
  )
}

///|
test "LegacyOverrideBuiltIns on a partial requires the getter in that same partial" {
  for
    (source, expected) in [
      (
        "[Exposed=*] interface A {}; [LegacyOverrideBuiltIns] partial interface A { getter any (DOMString key); };",
        true,
      ),
      (
        "[LegacyOverrideBuiltIns] partial interface A { getter any (DOMString key); }; [Exposed=*] interface A {};",
        true,
      ),
      (
        "[Exposed=*] interface A {}; [LegacyOverrideBuiltIns] partial interface A {};",
        false,
      ),
      (
        "[Exposed=*] interface A { getter any (DOMString key); }; [LegacyOverrideBuiltIns] partial interface A {};",
        false,
      ),
      (
        "[Exposed=*] interface A {}; [LegacyOverrideBuiltIns] partial interface A {}; partial interface A { getter any (DOMString key); };",
        false,
      ),
      (
        "[Exposed=*] interface A {}; [LegacyOverrideBuiltIns] partial interface A { getter any (unsigned long index); };",
        false,
      ),
      (
        "[Exposed=*, LegacyOverrideBuiltIns] interface A {}; [LegacyOverrideBuiltIns] partial interface A { getter any (DOMString key); };",
        true,
      ),
    ] {
    assert_eq(check_legacy_override_built_ins_source(source), expected)
  }
}

///|
test "Named getter checks resolve typedefs in interface and partial declarations" {
  let forms = [
    (
      "[Exposed=*, LegacyOverrideBuiltIns] interface A { getter any (", " key); };",
    ),
    (
      "[Exposed=*, LegacyOverrideBuiltIns] interface A {}; partial interface A { getter any (",
      " key); };",
    ),
    (
      "[Exposed=*] interface A {}; [LegacyOverrideBuiltIns] partial interface A { getter any (",
      " key); };",
    ),
    (
      "[Exposed=*] interface A {}; [Global=Window] partial interface A { getter any (",
      " key); };",
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
      "[Exposed=*, Global=Window] interface A {}; [LegacyOverrideBuiltIns] partial interface A { getter any (DOMString key); };",
      "[LegacyOverrideBuiltIns] partial interface A { getter any (DOMString key); }; [Exposed=*, Global=(Window,Worker)] interface A {};",
    ] {
    assert_false(check_legacy_override_built_ins_source(source))
  }
}

///|
test "Global interfaces cannot inherit LegacyOverrideBuiltIns applied through ancestor partials" {
  for
    ancestors in [
      "[Exposed=*] interface Parent {}; [LegacyOverrideBuiltIns] partial interface Parent { getter any (DOMString key); };",
      "[Exposed=*] interface Parent : Root {}; [Exposed=*] interface Root {}; [LegacyOverrideBuiltIns] partial interface Root { getter any (DOMString key); };",
    ] {
    let child = "[Exposed=*, Global=Window] interface Child : Parent {};"
    assert_false(check_legacy_override_built_ins_source(child + ancestors))
    assert_false(check_legacy_override_built_ins_source(ancestors + child))
    assert_true(
      check_legacy_override_built_ins_source(
        "[Exposed=*] interface Child : Parent {};" + ancestors,
      ),
    )
  }
}

///|
test "LegacyOverrideBuiltIns leaves malformed forms unrecognized" {
  for
    source in [
      "[Exposed=*, LegacyOverrideBuiltIns()] interface A {};", "[Exposed=*, LegacyOverrideBuiltIns=Name] interface A {};",
      "[Exposed=*] interface A {}; [LegacyOverrideBuiltIns()] partial interface A {};",
      "[Exposed=*, Global=Window] interface A {}; [LegacyOverrideBuiltIns()] partial interface A {};",
      "[Exposed=*] interface Parent {}; [LegacyOverrideBuiltIns()] partial interface Parent {}; [Exposed=*, Global=Window] interface Child : Parent {};",
    ] {
    assert_true(check_legacy_override_built_ins_source(source))
  }
}
