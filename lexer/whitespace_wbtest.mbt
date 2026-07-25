/// Whitebox tests for WHITESPACE regex, per WebIDL spec:
///   whitespace = /[\t\n\r ]+/

///|
/// === Single whitespace characters ===
test "whitespace - single space" {
  match WHITESPACE.execute(" ") {
    Some(m) => assert_eq(m.content().to_owned(), " ")
    None => fail("expected match")
  }
}

///|
test "whitespace - tab" {
  match WHITESPACE.execute("\t") {
    Some(m) => assert_eq(m.content().to_owned(), "\t")
    None => fail("expected match")
  }
}

///|
test "whitespace - newline" {
  match WHITESPACE.execute("\n") {
    Some(m) => assert_eq(m.content().to_owned(), "\n")
    None => fail("expected match")
  }
}

///|
test "whitespace - carriage return" {
  match WHITESPACE.execute("\r") {
    Some(m) => assert_eq(m.content().to_owned(), "\r")
    None => fail("expected match")
  }
}

///|
/// === Multiple whitespace characters ===
test "whitespace - multiple spaces" {
  match WHITESPACE.execute("   ") {
    Some(m) => assert_eq(m.content().to_owned(), "   ")
    None => fail("expected match")
  }
}

///|
test "whitespace - multiple tabs" {
  match WHITESPACE.execute("\t\t\t") {
    Some(m) => assert_eq(m.content().to_owned(), "\t\t\t")
    None => fail("expected match")
  }
}

///|
test "whitespace - multiple newlines" {
  match WHITESPACE.execute("\n\n\n") {
    Some(m) => assert_eq(m.content().to_owned(), "\n\n\n")
    None => fail("expected match")
  }
}

///|
test "whitespace - mixed" {
  match WHITESPACE.execute(" \t\n\r ") {
    Some(m) => assert_eq(m.content().to_owned(), " \t\n\r ")
    None => fail("expected match")
  }
}

///|
/// === Partial matches ===
test "whitespace - spaces then text" {
  match WHITESPACE.execute("  abc") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "  ")
      assert_eq(m.after().to_owned(), "abc")
    }
    None => fail("expected match")
  }
}

///|
test "whitespace - tab then code" {
  match WHITESPACE.execute("\tconst") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "\t")
      assert_eq(m.after().to_owned(), "const")
    }
    None => fail("expected match")
  }
}

///|
test "whitespace - newline then identifier" {
  match WHITESPACE.execute("\nfoo") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "\n")
      assert_eq(m.after().to_owned(), "foo")
    }
    None => fail("expected match")
  }
}

///|
test "whitespace - mixed then code" {
  match WHITESPACE.execute(" \t\n interface") {
    Some(m) => {
      assert_eq(m.content().to_owned(), " \t\n ")
      assert_eq(m.after().to_owned(), "interface")
    }
    None => fail("expected match")
  }
}

///|
/// === Should NOT match ===
test "whitespace - no match on empty string" {
  match WHITESPACE.execute("") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "whitespace - no match on letters" {
  match WHITESPACE.execute("abc") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "whitespace - no match on digits" {
  match WHITESPACE.execute("123") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "whitespace - no match on special chars" {
  match WHITESPACE.execute("@") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "whitespace - no match on identifier with leading underscore" {
  match WHITESPACE.execute("_foo") {
    Some(_) => fail("expected no match")
    None => ()
  }
}
