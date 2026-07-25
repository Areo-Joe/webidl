/// Blackbox tests for IDENTIFIER tokenization, per WebIDL spec:
///   identifier = /[_-]?[A-Za-z][0-9A-Z_a-z-]*/

///|
/// === Basic: letter only ===
test "identifier - single lowercase" {
  let result = tokenize("a") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "a")
}

///|
test "identifier - single uppercase" {
  let result = tokenize("Z") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "Z")
}

///|
test "identifier - simple word" {
  let result = tokenize("foo") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "foo")
}

///|
test "identifier - all uppercase" {
  let result = tokenize("BAR") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "BAR")
}

///|
test "identifier - camelCase" {
  let result = tokenize("helloWorld") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "helloWorld")
}

///|
/// === With digits ===
test "identifier - trailing digits" {
  let result = tokenize("foo123") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "foo123")
}

///|
test "identifier - interleaved digits" {
  let result = tokenize("a1b2c3") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "a1b2c3")
}

///|
test "identifier - digits at end of long name" {
  let result = tokenize("nodeType1") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "nodeType1")
}

///|
/// === With underscores ===
test "identifier - internal underscore" {
  let result = tokenize("foo_bar") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "foo_bar")
}

///|
test "identifier - multiple underscores" {
  let result = tokenize("foo__bar") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "foo__bar")
}

///|
test "identifier - underscore suffix" {
  let result = tokenize("foo_") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "foo_")
}

///|
/// === With hyphens (WebIDL style) ===
test "identifier - internal hyphen" {
  let result = tokenize("long-long") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "long-long")
}

///|
test "identifier - multiple hyphens" {
  let result = tokenize("unsigned-long-long") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "unsigned-long-long")
}

///|
test "identifier - hyphen suffix" {
  let result = tokenize("foo-") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "foo-")
}

///|
/// === Leading underscore (escaping reserved words per spec) ===
test "identifier - leading underscore escaping" {
  let result = tokenize("_interface") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "_interface")
}

///|
test "identifier - leading underscore with digits after" {
  let result = tokenize("_foo123") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "_foo123")
}

///|
test "identifier - leading underscore internal hyphen" {
  let result = tokenize("_foo-bar") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "_foo-bar")
}

///|
/// === Leading hyphen ===
test "identifier - leading hyphen" {
  let result = tokenize("-foo") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "-foo")
}

///|
test "identifier - leading hyphen with digits" {
  let result = tokenize("-foo123") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "-foo123")
}

///|
test "identifier - leading hyphen internal underscore" {
  let result = tokenize("-foo_bar") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "-foo_bar")
}

///|
/// === Mixed (all character classes) ===
test "identifier - leading underscore hyphen digits" {
  let result = tokenize("_foo-bar-123") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "_foo-bar-123")
}

///|
test "identifier - leading hyphen underscore digits" {
  let result = tokenize("-foo_bar_123") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "-foo_bar_123")
}

///|
/// === Edge cases ===
test "identifier - lone underscore is not an identifier" {
  // [_\-]? matches "_", but [A-Za-z] requires a letter after it
  let result = tokenize("_") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Other)
  assert_eq(s.to_owned(), "_")
}

///|
test "identifier - lone hyphen is not an identifier" {
  let result = tokenize("-") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Other)
  assert_eq(s.to_owned(), "-")
}

///|
test "identifier - leading underscore then digit splits" {
  // "_1" -> Other("_") + Integer("1") since [A-Za-z] requires a letter
  let result = tokenize("_1") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Other)
  assert_eq(s0.to_owned(), "_")
  assert_true(t1 is TokenType::Integer)
  assert_eq(s1.to_owned(), "1")
}

///|
test "identifier - leading hyphen then digit splits" {
  // "-1" -> INTEGER("-1") since INTEGER handles the -? prefix
  let result = tokenize("-1") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "-1")
}

///|
/// === Longest match: IDENTIFIER beats INTEGER ===
test "identifier - beats integer on letter-starting tokens" {
  let result = tokenize("foo123") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, _) = result[0]
  assert_true(t is TokenType::Identifier)
}

///|
test "identifier - keywords tokenized as identifier in current lexer" {
  let result = tokenize("const") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Identifier)
  assert_eq(s.to_owned(), "const")
}

///|
test "identifier - WebIDL keywords are identifiers in current lexer" {
  for
    keyword in [
      "interface", "attribute", "readonly", "stringifier", "static", "getter", "setter",
      "deleter", "inherit", "partial", "mixin", "includes", "typedef", "callback",
      "enum", "dictionary", "namespace", "constructor", "iterable", "maplike", "setlike",
      "required", "optional", "unsigned", "long", "short", "float", "double", "boolean",
      "byte", "octet", "bigint", "any", "undefined", "null", "true", "false", "Infinity",
      "NaN", "DOMString", "USVString", "ByteString", "object", "symbol", "record",
      "sequence", "FrozenArray", "Promise",
    ] {
    let result = tokenize(keyword) catch { _ => fail("unexpected") }
    assert_eq(result.length(), 1)
    assert_true(result[0].0 is TokenType::Identifier)
    assert_eq(result[0].1.to_owned(), keyword)
  }
}

///|
/// === Not matching other token types ===
test "identifier - does not match digits only" {
  let result = tokenize("123") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, _) = result[0]
  assert_true(t is TokenType::Integer)
}

///|
test "identifier - does not match special characters" {
  let result = tokenize("@foo") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, _) = result[0]
  let (t1, _) = result[1]
  assert_true(t0 is TokenType::Other)
  assert_true(t1 is TokenType::Identifier)
}

///|
test "identifier - does not consume dot" {
  let result = tokenize("foo.bar") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 3)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  let (t2, s2) = result[2]
  assert_true(t0 is TokenType::Identifier)
  assert_eq(s0.to_owned(), "foo")
  assert_true(t1 is TokenType::Other)
  assert_eq(s1.to_owned(), ".")
  assert_true(t2 is TokenType::Identifier)
  assert_eq(s2.to_owned(), "bar")
}

///|
test "identifier - does not consume semicolon" {
  let result = tokenize("foo;") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Identifier)
  assert_eq(s0.to_owned(), "foo")
  assert_true(t1 is TokenType::Other)
  assert_eq(s1.to_owned(), ";")
}
