/// Whitebox tests for STRING regex, per WebIDL spec:
///   string = /"[^"]*/

///|
/// === Basic strings ===
test "string - empty" {
  match STRING.execute("\"\"") {
    Some(m) => assert_eq(m.content().to_owned(), "\"\"")
    None => fail("expected match")
  }
}

///|
test "string - simple word" {
  match STRING.execute("\"hello\"") {
    Some(m) => assert_eq(m.content().to_owned(), "\"hello\"")
    None => fail("expected match")
  }
}

///|
test "string - single character" {
  match STRING.execute("\"a\"") {
    Some(m) => assert_eq(m.content().to_owned(), "\"a\"")
    None => fail("expected match")
  }
}

///|
test "string - with spaces" {
  match STRING.execute("\"hello world\"") {
    Some(m) => assert_eq(m.content().to_owned(), "\"hello world\"")
    None => fail("expected match")
  }
}

///|
test "string - with digits" {
  match STRING.execute("\"12345\"") {
    Some(m) => assert_eq(m.content().to_owned(), "\"12345\"")
    None => fail("expected match")
  }
}

///|
test "string - with special characters" {
  match STRING.execute("\"foo@bar#baz%^&*()\"") {
    Some(m) => assert_eq(m.content().to_owned(), "\"foo@bar#baz%^&*()\"")
    None => fail("expected match")
  }
}

///|
test "string - with underscores and hyphens" {
  match STRING.execute("\"foo_bar-baz\"") {
    Some(m) => assert_eq(m.content().to_owned(), "\"foo_bar-baz\"")
    None => fail("expected match")
  }
}

///|
test "string - long" {
  match STRING.execute("\"Lorem ipsum dolor sit amet\"") {
    Some(m) =>
      assert_eq(m.content().to_owned(), "\"Lorem ipsum dolor sit amet\"")
    None => fail("expected match")
  }
}

///|
/// === String with newlines inside ===
test "string - with newline" {
  match STRING.execute("\"hello\nworld\"") {
    Some(m) => assert_eq(m.content().to_owned(), "\"hello\nworld\"")
    None => fail("expected match")
  }
}

///|
test "string - with tab" {
  match STRING.execute("\"hello\tworld\"") {
    Some(m) => assert_eq(m.content().to_owned(), "\"hello\tworld\"")
    None => fail("expected match")
  }
}

///|
/// === Should NOT match ===
test "string - no match on bare word" {
  match STRING.execute("hello") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "string - no match on empty input" {
  match STRING.execute("") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "string - no match on opening quote only" {
  match STRING.execute("\"") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "string - no match on digits" {
  match STRING.execute("123") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "string - no match on number" {
  match STRING.execute("42") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
/// === Partial matches ===
test "string - partial unclosed string" {
  match STRING.execute("\"hello") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "string - partial quoted string then identifier" {
  match STRING.execute("\"hello\"world") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "\"hello\"")
      assert_eq(m.after().to_owned(), "world")
    }
    None => fail("expected match")
  }
}

///|
test "string - partial quote then number" {
  match STRING.execute("\"hello\"42") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "\"hello\"")
      assert_eq(m.after().to_owned(), "42")
    }
    None => fail("expected match")
  }
}

///|
test "string - escaped quote treated as literal backslash-quote" {
  // Spec regex doesn't understand escape sequences.
  // "\"hello\" matches up to the first unescaped " after the backslash.
  match STRING.execute("\"\\\"hello\\\"\"") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "\"\\\"")
      assert_eq(m.after().to_owned(), "hello\\\"\"")
    }
    None => fail("expected match")
  }
}

///|
test "string - trailing text after closing quote" {
  match STRING.execute("\"foo\";") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "\"foo\"")
      assert_eq(m.after().to_owned(), ";")
    }
    None => fail("expected match")
  }
}
