///|
test "Operations without identifiers must be special operations" {
  let prefix = "[Exposed=*] interface A { "
  let suffix = " };"
  for
    (declaration, expected) in [
      ("long ();", false),
      ("static long ();", false),
      ("getter long (unsigned long index);", true),
      ("setter undefined (unsigned long index, long value);", true),
      ("deleter undefined (DOMString name);", true),
      ("long item();", true),
      ("getter long item(unsigned long index);", true),
      ("constructor();", true),
      ("stringifier;", true),
    ] {
    assert_eq(check_source(prefix + declaration + suffix), expected)
  }
}

///|
test "Operations without identifiers are checked in every declaration context" {
  for
    (source, expected) in [
      ("interface mixin M { long (); };", false),
      ("interface mixin M { long run(); };", true),
      ("[Exposed=*] interface A {}; partial interface A { long (); };", false),
      ("[Exposed=*] interface A {}; partial interface A { long run(); };", true),
      ("interface mixin M {}; partial interface mixin M { long (); };", false),
      ("interface mixin M {}; partial interface mixin M { long run(); };", true),
      ("namespace N { long (); };", false),
      ("namespace N { long run(); };", true),
      ("namespace N {}; partial namespace N { long (); };", false),
      ("namespace N {}; partial namespace N { long run(); };", true),
      ("callback interface C { undefined (); };", false),
      ("callback interface C { undefined run(); };", true),
    ] {
    assert_eq(check_source(source), expected)
  }
}
