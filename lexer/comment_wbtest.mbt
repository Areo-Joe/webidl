/// Whitebox tests for COMMENT regex, per WebIDL spec:
///   comment = /\/\/.*|\/\*(.|\n)*?\*\//

///|
/// === Line comments: //[^\n]* ===
test "comment - line empty" {
  match COMMENT.execute("//\n") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "//")
      assert_eq(m.after().to_owned(), "\n")
    }
    None => fail("expected match")
  }
}

///|
test "comment - line simple" {
  match COMMENT.execute("// hello") {
    Some(m) => assert_eq(m.content().to_owned(), "// hello")
    None => fail("expected match")
  }
}

///|
test "comment - line with special chars" {
  match COMMENT.execute("// foo @ bar # baz $100") {
    Some(m) => assert_eq(m.content().to_owned(), "// foo @ bar # baz $100")
    None => fail("expected match")
  }
}

///|
test "comment - line with digits" {
  match COMMENT.execute("// 12345") {
    Some(m) => assert_eq(m.content().to_owned(), "// 12345")
    None => fail("expected match")
  }
}

///|
test "comment - line stops at newline" {
  match COMMENT.execute("// hello\nworld") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "// hello")
      assert_eq(m.after().to_owned(), "\nworld")
    }
    None => fail("expected match")
  }
}

///|
test "comment - line at end of input" {
  match COMMENT.execute("// end") {
    Some(m) => assert_eq(m.content().to_owned(), "// end")
    None => fail("expected match")
  }
}

///|
test "comment - line then code" {
  match COMMENT.execute("// comment\ncode") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "// comment")
      assert_eq(m.after().to_owned(), "\ncode")
    }
    None => fail("expected match")
  }
}

///|
test "comment - line single slash is not a comment" {
  match COMMENT.execute("/") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
/// === Block comments: /\*.*?\*/ ===
test "comment - block simple" {
  match COMMENT.execute("/* hello */") {
    Some(m) => assert_eq(m.content().to_owned(), "/* hello */")
    None => fail("expected match")
  }
}

///|
test "comment - block empty" {
  match COMMENT.execute("/**/") {
    Some(m) => assert_eq(m.content().to_owned(), "/**/")
    None => fail("expected match")
  }
}

///|
test "comment - block multi-line" {
  match COMMENT.execute("/* hello\nworld */") {
    Some(m) => assert_eq(m.content().to_owned(), "/* hello\nworld */")
    None => fail("expected match")
  }
}

///|
test "comment - block with special chars" {
  match COMMENT.execute("/* @#$% &*() */") {
    Some(m) => assert_eq(m.content().to_owned(), "/* @#$% &*() */")
    None => fail("expected match")
  }
}

///|
test "comment - block with code-like content" {
  match COMMENT.execute("/* const a = 42; */") {
    Some(m) => assert_eq(m.content().to_owned(), "/* const a = 42; */")
    None => fail("expected match")
  }
}

///|
test "comment - block with tabs and newlines" {
  match COMMENT.execute("/* line1\n\tline2\n\tline3 */") {
    Some(m) =>
      assert_eq(m.content().to_owned(), "/* line1\n\tline2\n\tline3 */")
    None => fail("expected match")
  }
}

///|
test "comment - block non-greedy stops at first star-slash" {
  // Non-greedy .*? should stop at the first */
  match COMMENT.execute("/* a /* b */ c */") {
    Some(m) => {
      // Matches up to first */
      assert_eq(m.content().to_owned(), "/* a /* b */")
      assert_eq(m.after().to_owned(), " c */")
    }
    None => fail("expected match")
  }
}

///|
test "comment - block then code" {
  match COMMENT.execute("/* comment */code") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "/* comment */")
      assert_eq(m.after().to_owned(), "code")
    }
    None => fail("expected match")
  }
}

///|
test "comment - block unclosed" {
  match COMMENT.execute("/* unclosed") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "comment - block unmatched opening" {
  match COMMENT.execute("/*/") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
/// === Should NOT match ===
test "comment - no match on plain text" {
  match COMMENT.execute("hello") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "comment - no match on empty input" {
  match COMMENT.execute("") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "comment - no match on single slash" {
  match COMMENT.execute("/") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "comment - no match on triple slash" {
  match COMMENT.execute("///") {
    Some(m) => assert_eq(m.content().to_owned(), "///")
    None => fail("expected match")
  }
}
