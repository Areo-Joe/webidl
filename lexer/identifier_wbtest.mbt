/// Whitebox tests for IDENTIFIER regex, per WebIDL spec:
///   identifier = /[_-]?[A-Za-z][0-9A-Z_a-z-]*/

///|
/// === Basic: letter only ===
test "identifier - single lowercase" {
  match IDENTIFIER.execute("a") {
    Some(m) => assert_eq(m.content().to_owned(), "a")
    None => fail("expected match")
  }
}

///|
test "identifier - single uppercase" {
  match IDENTIFIER.execute("Z") {
    Some(m) => assert_eq(m.content().to_owned(), "Z")
    None => fail("expected match")
  }
}

///|
test "identifier - simple word" {
  match IDENTIFIER.execute("foo") {
    Some(m) => assert_eq(m.content().to_owned(), "foo")
    None => fail("expected match")
  }
}

///|
test "identifier - all uppercase" {
  match IDENTIFIER.execute("BAR") {
    Some(m) => assert_eq(m.content().to_owned(), "BAR")
    None => fail("expected match")
  }
}

///|
test "identifier - camelCase" {
  match IDENTIFIER.execute("helloWorld") {
    Some(m) => assert_eq(m.content().to_owned(), "helloWorld")
    None => fail("expected match")
  }
}

///|
/// === With digits ===
test "identifier - trailing digits" {
  match IDENTIFIER.execute("foo123") {
    Some(m) => assert_eq(m.content().to_owned(), "foo123")
    None => fail("expected match")
  }
}

///|
test "identifier - interleaved digits" {
  match IDENTIFIER.execute("a1b2c3") {
    Some(m) => assert_eq(m.content().to_owned(), "a1b2c3")
    None => fail("expected match")
  }
}

///|
test "identifier - digits at end of long name" {
  match IDENTIFIER.execute("nodeType1") {
    Some(m) => assert_eq(m.content().to_owned(), "nodeType1")
    None => fail("expected match")
  }
}

///|
/// === With underscores ===
test "identifier - internal underscore" {
  match IDENTIFIER.execute("foo_bar") {
    Some(m) => assert_eq(m.content().to_owned(), "foo_bar")
    None => fail("expected match")
  }
}

///|
test "identifier - multiple underscores" {
  match IDENTIFIER.execute("foo__bar") {
    Some(m) => assert_eq(m.content().to_owned(), "foo__bar")
    None => fail("expected match")
  }
}

///|
test "identifier - underscore suffix" {
  match IDENTIFIER.execute("foo_") {
    Some(m) => assert_eq(m.content().to_owned(), "foo_")
    None => fail("expected match")
  }
}

///|
/// === With hyphens (WebIDL style) ===
test "identifier - internal hyphen" {
  match IDENTIFIER.execute("long-long") {
    Some(m) => assert_eq(m.content().to_owned(), "long-long")
    None => fail("expected match")
  }
}

///|
test "identifier - multiple hyphens" {
  match IDENTIFIER.execute("unsigned-long-long") {
    Some(m) => assert_eq(m.content().to_owned(), "unsigned-long-long")
    None => fail("expected match")
  }
}

///|
test "identifier - hyphen suffix" {
  match IDENTIFIER.execute("foo-") {
    Some(m) => assert_eq(m.content().to_owned(), "foo-")
    None => fail("expected match")
  }
}

///|
/// === Leading underscore (escaping reserved words per spec) ===
test "identifier - leading underscore escaping" {
  match IDENTIFIER.execute("_interface") {
    Some(m) => assert_eq(m.content().to_owned(), "_interface")
    None => fail("expected match")
  }
}

///|
test "identifier - leading underscore with digits" {
  match IDENTIFIER.execute("_foo123") {
    Some(m) => assert_eq(m.content().to_owned(), "_foo123")
    None => fail("expected match")
  }
}

///|
test "identifier - leading underscore internal hyphen" {
  match IDENTIFIER.execute("_foo-bar") {
    Some(m) => assert_eq(m.content().to_owned(), "_foo-bar")
    None => fail("expected match")
  }
}

///|
/// === Leading hyphen ===
test "identifier - leading hyphen" {
  match IDENTIFIER.execute("-foo") {
    Some(m) => assert_eq(m.content().to_owned(), "-foo")
    None => fail("expected match")
  }
}

///|
test "identifier - leading hyphen with digits" {
  match IDENTIFIER.execute("-foo123") {
    Some(m) => assert_eq(m.content().to_owned(), "-foo123")
    None => fail("expected match")
  }
}

///|
test "identifier - leading hyphen internal underscore" {
  match IDENTIFIER.execute("-foo_bar") {
    Some(m) => assert_eq(m.content().to_owned(), "-foo_bar")
    None => fail("expected match")
  }
}

///|
/// === Mixed (all character classes) ===
test "identifier - leading underscore hyphen digits" {
  match IDENTIFIER.execute("_foo-bar-123") {
    Some(m) => assert_eq(m.content().to_owned(), "_foo-bar-123")
    None => fail("expected match")
  }
}

///|
test "identifier - leading hyphen underscore digits" {
  match IDENTIFIER.execute("-foo_bar_123") {
    Some(m) => assert_eq(m.content().to_owned(), "-foo_bar_123")
    None => fail("expected match")
  }
}

///|
/// === Should NOT match ===
test "identifier - no match on lone underscore" {
  match IDENTIFIER.execute("_") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "identifier - no match on lone hyphen" {
  match IDENTIFIER.execute("-") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "identifier - no match on underscore then digit" {
  match IDENTIFIER.execute("_1") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "identifier - no match on digits only" {
  match IDENTIFIER.execute("123") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "identifier - no match on empty string" {
  match IDENTIFIER.execute("") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "identifier - no match on special char" {
  match IDENTIFIER.execute("@") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "identifier - no match on dot" {
  match IDENTIFIER.execute(".") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
/// === Partial matches ===
test "identifier - partial foo.bar leaves .bar" {
  match IDENTIFIER.execute("foo.bar") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "foo")
      assert_eq(m.after().to_owned(), ".bar")
    }
    None => fail("expected match")
  }
}

///|
test "identifier - partial foo; leaves ;" {
  match IDENTIFIER.execute("foo;") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "foo")
      assert_eq(m.after().to_owned(), ";")
    }
    None => fail("expected match")
  }
}

///|
test "identifier - all WebIDL keywords match" {
  for
    keyword in [
      "const", "interface", "attribute", "readonly", "stringifier", "static", "getter",
      "setter", "deleter", "inherit", "partial", "mixin", "includes", "typedef",
      "callback", "enum", "dictionary", "namespace", "constructor", "iterable", "maplike",
      "setlike", "required", "optional", "unsigned", "long", "short", "float", "double",
      "boolean", "byte", "octet", "bigint", "any", "undefined", "null", "true", "false",
      "Infinity", "NaN", "DOMString", "USVString", "ByteString", "object", "symbol",
      "record", "sequence", "FrozenArray", "Promise",
    ] {
    match IDENTIFIER.execute(keyword) {
      Some(m) => assert_eq(m.content().to_owned(), keyword)
      None => fail("expected keyword '" + keyword + "' to match")
    }
  }
}
