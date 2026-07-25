/// Whitebox tests for INTEGER regex, per WebIDL spec:
///   integer = /-?([1-9][0-9]*|0[Xx][0-9A-Fa-f]+|0[0-7]*)/

///|
/// === Alt 1: [1-9][0-9]* (decimal with non-zero first digit) ===
test "integer - decimal single digit 1" {
  match INTEGER.execute("1") {
    Some(m) => assert_eq(m.content().to_owned(), "1")
    None => fail("expected match")
  }
}

///|
test "integer - decimal single digit 9" {
  match INTEGER.execute("9") {
    Some(m) => assert_eq(m.content().to_owned(), "9")
    None => fail("expected match")
  }
}

///|
test "integer - decimal multi digit" {
  match INTEGER.execute("42") {
    Some(m) => assert_eq(m.content().to_owned(), "42")
    None => fail("expected match")
  }
}

///|
test "integer - decimal large" {
  match INTEGER.execute("1234567890") {
    Some(m) => assert_eq(m.content().to_owned(), "1234567890")
    None => fail("expected match")
  }
}

///|
/// === Alt 1 with -? prefix (negative decimal) ===
test "integer - negative decimal small" {
  match INTEGER.execute("-1") {
    Some(m) => assert_eq(m.content().to_owned(), "-1")
    None => fail("expected match")
  }
}

///|
test "integer - negative decimal large" {
  match INTEGER.execute("-42") {
    Some(m) => assert_eq(m.content().to_owned(), "-42")
    None => fail("expected match")
  }
}

///|
/// === Alt 2: 0[Xx][0-9A-Fa-f]+ (hex) ===
test "integer - hex lowercase x" {
  match INTEGER.execute("0x1A") {
    Some(m) => assert_eq(m.content().to_owned(), "0x1A")
    None => fail("expected match")
  }
}

///|
test "integer - hex uppercase X" {
  match INTEGER.execute("0XFF") {
    Some(m) => assert_eq(m.content().to_owned(), "0XFF")
    None => fail("expected match")
  }
}

///|
test "integer - hex single digit" {
  match INTEGER.execute("0x0") {
    Some(m) => assert_eq(m.content().to_owned(), "0x0")
    None => fail("expected match")
  }
}

///|
test "integer - hex uppercase X single digit" {
  match INTEGER.execute("0X0") {
    Some(m) => assert_eq(m.content().to_owned(), "0X0")
    None => fail("expected match")
  }
}

///|
test "integer - hex all hex digits A-F" {
  match INTEGER.execute("0xDEADBEEF") {
    Some(m) => assert_eq(m.content().to_owned(), "0xDEADBEEF")
    None => fail("expected match")
  }
}

///|
test "integer - hex mixed case" {
  match INTEGER.execute("0xAbCdEf") {
    Some(m) => assert_eq(m.content().to_owned(), "0xAbCdEf")
    None => fail("expected match")
  }
}

///|
/// === Alt 2 with -? prefix (negative hex) ===
test "integer - negative hex" {
  match INTEGER.execute("-0x1A") {
    Some(m) => assert_eq(m.content().to_owned(), "-0x1A")
    None => fail("expected match")
  }
}

///|
/// === Alt 3: 0[0-7]* (octal) ===
test "integer - octal zero" {
  match INTEGER.execute("0") {
    Some(m) => assert_eq(m.content().to_owned(), "0")
    None => fail("expected match")
  }
}

///|
test "integer - octal single digit" {
  match INTEGER.execute("01") {
    Some(m) => assert_eq(m.content().to_owned(), "01")
    None => fail("expected match")
  }
}

///|
test "integer - octal multi digit" {
  match INTEGER.execute("0777") {
    Some(m) => assert_eq(m.content().to_owned(), "0777")
    None => fail("expected match")
  }
}

///|
test "integer - octal leading zeros" {
  match INTEGER.execute("007") {
    Some(m) => assert_eq(m.content().to_owned(), "007")
    None => fail("expected match")
  }
}

///|
/// === Alt 3 with -? prefix (negative octal) ===
test "integer - negative octal" {
  match INTEGER.execute("-0777") {
    Some(m) => assert_eq(m.content().to_owned(), "-0777")
    None => fail("expected match")
  }
}

///|
test "integer - negative zero" {
  match INTEGER.execute("-0") {
    Some(m) => assert_eq(m.content().to_owned(), "-0")
    None => fail("expected match")
  }
}

///|
/// === Should NOT match ===
test "integer - no match on letters" {
  match INTEGER.execute("abc") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "integer - no match on special chars" {
  match INTEGER.execute("@") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "integer - no match on empty string" {
  match INTEGER.execute("") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "integer - no match on leading dot" {
  match INTEGER.execute(".5") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
/// === Partial matches (regex matches prefix, leaves rest via .after()) ===
test "integer - partial 42abc leaves abc" {
  match INTEGER.execute("42abc") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "42")
      assert_eq(m.after().to_owned(), "abc")
    }
    None => fail("expected match")
  }
}

///|
test "integer - partial 0x leaves x" {
  match INTEGER.execute("0x") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "0")
      assert_eq(m.after().to_owned(), "x")
    }
    None => fail("expected match")
  }
}

///|
test "integer - partial 0X leaves X" {
  match INTEGER.execute("0X") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "0")
      assert_eq(m.after().to_owned(), "X")
    }
    None => fail("expected match")
  }
}

///|
test "integer - partial -0x leaves x" {
  match INTEGER.execute("-0x") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "-0")
      assert_eq(m.after().to_owned(), "x")
    }
    None => fail("expected match")
  }
}

///|
test "integer - partial 08 leaves 8" {
  match INTEGER.execute("08") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "0")
      assert_eq(m.after().to_owned(), "8")
    }
    None => fail("expected match")
  }
}

///|
test "integer - partial 09 leaves 9" {
  match INTEGER.execute("09") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "0")
      assert_eq(m.after().to_owned(), "9")
    }
    None => fail("expected match")
  }
}

///|
test "integer - no match on lone minus" {
  match INTEGER.execute("-") {
    Some(_) => fail("expected no match")
    None => ()
  }
}
