/// Whitebox tests for OTHER regex, per WebIDL spec:
///   other = /[^\t\n\r 0-9A-Za-z]/

///|
/// === Punctuation characters that should match ===
test "other - left brace" {
  match OTHER.execute("{") {
    Some(m) => assert_eq(m.content().to_owned(), "{")
    None => fail("expected match")
  }
}

///|
test "other - right brace" {
  match OTHER.execute("}") {
    Some(m) => assert_eq(m.content().to_owned(), "}")
    None => fail("expected match")
  }
}

///|
test "other - left paren" {
  match OTHER.execute("(") {
    Some(m) => assert_eq(m.content().to_owned(), "(")
    None => fail("expected match")
  }
}

///|
test "other - right paren" {
  match OTHER.execute(")") {
    Some(m) => assert_eq(m.content().to_owned(), ")")
    None => fail("expected match")
  }
}

///|
test "other - left bracket" {
  match OTHER.execute("[") {
    Some(m) => assert_eq(m.content().to_owned(), "[")
    None => fail("expected match")
  }
}

///|
test "other - right bracket" {
  match OTHER.execute("]") {
    Some(m) => assert_eq(m.content().to_owned(), "]")
    None => fail("expected match")
  }
}

///|
test "other - semicolon" {
  match OTHER.execute(";") {
    Some(m) => assert_eq(m.content().to_owned(), ";")
    None => fail("expected match")
  }
}

///|
test "other - colon" {
  match OTHER.execute(":") {
    Some(m) => assert_eq(m.content().to_owned(), ":")
    None => fail("expected match")
  }
}

///|
test "other - comma" {
  match OTHER.execute(",") {
    Some(m) => assert_eq(m.content().to_owned(), ",")
    None => fail("expected match")
  }
}

///|
test "other - dot" {
  match OTHER.execute(".") {
    Some(m) => assert_eq(m.content().to_owned(), ".")
    None => fail("expected match")
  }
}

///|
test "other - equals" {
  match OTHER.execute("=") {
    Some(m) => assert_eq(m.content().to_owned(), "=")
    None => fail("expected match")
  }
}

///|
test "other - less than" {
  match OTHER.execute("<") {
    Some(m) => assert_eq(m.content().to_owned(), "<")
    None => fail("expected match")
  }
}

///|
test "other - greater than" {
  match OTHER.execute(">") {
    Some(m) => assert_eq(m.content().to_owned(), ">")
    None => fail("expected match")
  }
}

///|
test "other - question mark" {
  match OTHER.execute("?") {
    Some(m) => assert_eq(m.content().to_owned(), "?")
    None => fail("expected match")
  }
}

///|
test "other - at sign" {
  match OTHER.execute("@") {
    Some(m) => assert_eq(m.content().to_owned(), "@")
    None => fail("expected match")
  }
}

///|
test "other - exclamation" {
  match OTHER.execute("!") {
    Some(m) => assert_eq(m.content().to_owned(), "!")
    None => fail("expected match")
  }
}

///|
test "other - hash" {
  match OTHER.execute("#") {
    Some(m) => assert_eq(m.content().to_owned(), "#")
    None => fail("expected match")
  }
}

///|
test "other - dollar" {
  match OTHER.execute("$") {
    Some(m) => assert_eq(m.content().to_owned(), "$")
    None => fail("expected match")
  }
}

///|
test "other - percent" {
  match OTHER.execute("%") {
    Some(m) => assert_eq(m.content().to_owned(), "%")
    None => fail("expected match")
  }
}

///|
test "other - caret" {
  match OTHER.execute("^") {
    Some(m) => assert_eq(m.content().to_owned(), "^")
    None => fail("expected match")
  }
}

///|
test "other - ampersand" {
  match OTHER.execute("&") {
    Some(m) => assert_eq(m.content().to_owned(), "&")
    None => fail("expected match")
  }
}

///|
test "other - asterisk" {
  match OTHER.execute("*") {
    Some(m) => assert_eq(m.content().to_owned(), "*")
    None => fail("expected match")
  }
}

///|
test "other - plus" {
  match OTHER.execute("+") {
    Some(m) => assert_eq(m.content().to_owned(), "+")
    None => fail("expected match")
  }
}

///|
test "other - minus" {
  match OTHER.execute("-") {
    Some(m) => assert_eq(m.content().to_owned(), "-")
    None => fail("expected match")
  }
}

///|
test "other - underscore" {
  match OTHER.execute("_") {
    Some(m) => assert_eq(m.content().to_owned(), "_")
    None => fail("expected match")
  }
}

///|
test "other - pipe" {
  match OTHER.execute("|") {
    Some(m) => assert_eq(m.content().to_owned(), "|")
    None => fail("expected match")
  }
}

///|
test "other - tilde" {
  match OTHER.execute("~") {
    Some(m) => assert_eq(m.content().to_owned(), "~")
    None => fail("expected match")
  }
}

///|
test "other - backtick" {
  match OTHER.execute("`") {
    Some(m) => assert_eq(m.content().to_owned(), "`")
    None => fail("expected match")
  }
}

///|
test "other - single quote" {
  match OTHER.execute("'") {
    Some(m) => assert_eq(m.content().to_owned(), "'")
    None => fail("expected match")
  }
}

///|
test "other - slash" {
  match OTHER.execute("/") {
    Some(m) => assert_eq(m.content().to_owned(), "/")
    None => fail("expected match")
  }
}

///|
test "other - backslash" {
  match OTHER.execute("\\") {
    Some(m) => assert_eq(m.content().to_owned(), "\\")
    None => fail("expected match")
  }
}

///|
/// === Single character match only (no quantifier) ===
test "other - matches only first char of multiple" {
  match OTHER.execute("@foo") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "@")
      assert_eq(m.after().to_owned(), "foo")
    }
    None => fail("expected match")
  }
}

///|
test "other - matches only one char" {
  match OTHER.execute("@@") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "@")
      assert_eq(m.after().to_owned(), "@")
    }
    None => fail("expected match")
  }
}

///|
/// === Should NOT match (characters in exclusion set) ===
test "other - no match on space" {
  match OTHER.execute(" ") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "other - no match on tab" {
  match OTHER.execute("\t") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "other - no match on newline" {
  match OTHER.execute("\n") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "other - no match on carriage return" {
  match OTHER.execute("\r") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "other - no match on digit" {
  match OTHER.execute("5") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "other - no match on lowercase letter" {
  match OTHER.execute("a") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "other - no match on uppercase letter" {
  match OTHER.execute("Z") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "other - no match on empty string" {
  match OTHER.execute("") {
    Some(_) => fail("expected no match")
    None => ()
  }
}
