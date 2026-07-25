///|
test "tokenize longest named terminals" {
  match (try! tokenize("a1 1.0 -42 1e+2 \"x\"")) {
    [
      (Identifier, "a1"),
      (Decimal, "1.0"),
      (Integer, "-42"),
      (Decimal, "1e+2"),
      (String, "\"x\""),
    ] => ()
    _ => fail("unexpected token sequence")
  }
}

///|
test "tokenize named terminal forms" {
  for input in ["0", "-0", "42", "0x1A", "077"] {
    match (try! tokenize(input)) {
      [(Integer, text)] => assert_eq(text, input[:])
      _ => fail("integer was not tokenized as one integer")
    }
  }
  for input in ["1.", ".5", "1.5e-3", "1E+2"] {
    match (try! tokenize(input)) {
      [(Decimal, text)] => assert_eq(text, input[:])
      _ => fail("decimal was not tokenized as one decimal")
    }
  }
  for input in ["a1", "_name", "-name", "name-with-hyphen"] {
    match (try! tokenize(input)) {
      [(Identifier, text)] => assert_eq(text, input[:])
      _ => fail("identifier was not tokenized as one identifier")
    }
  }
  for input in ["\"\"", "\"hello world\"", "\"line\nbreak\""] {
    match (try! tokenize(input)) {
      [(String, text)] => assert_eq(text, input[:])
      _ => fail("string was not tokenized as one string")
    }
  }
}

///|
test "tokenize literal terminals over identifiers" {
  match (try! tokenize("long longer long-foo Const -Infinity")) {
    [
      (Keyword, "long"),
      (Identifier, "longer"),
      (Identifier, "long-foo"),
      (Identifier, "Const"),
      (Keyword, "-Infinity"),
    ] => ()
    _ => fail("unexpected token sequence")
  }
}

///|
test "tokenize punctuation with longest match" {
  match (try! tokenize("... .. @")) {
    [(Punctuation, "..."), (Punctuation, "."), (Punctuation, "."), (Other, "@")] =>
      ()
    _ => fail("unexpected token sequence")
  }
}

///|
test "tokenize non-grammar other terminals" {
  match (try! tokenize("@#$😀")) {
    [(Other, "@"), (Other, "#"), (Other, "$"), (Other, "😀")] => ()
    _ => fail("unexpected token sequence")
  }
}

///|
test "tokenize ignores whitespace and comments" {
  match
    (try! tokenize(
      " interface /* block\ncomment */ Foo // line comment\n { }; ",
    )) {
    [
      (Keyword, "interface"),
      (Identifier, "Foo"),
      (Punctuation, "{"),
      (Punctuation, "}"),
      (Punctuation, ";"),
    ] => ()
    _ => fail("unexpected token sequence")
  }
}
