/// Blackbox tests for INTEGER tokenization, per WebIDL spec:
///   integer = /-?([1-9][0-9]*|0[Xx][0-9A-Fa-f]+|0[0-7]*)/

///| === Alt 1: [1-9][0-9]* (decimal with non-zero first digit) ===

test "integer - decimal single digit 1" {
  let result = tokenize("1") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "1")
}

test "integer - decimal single digit 9" {
  let result = tokenize("9") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "9")
}

test "integer - decimal multi digit" {
  let result = tokenize("42") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "42")
}

test "integer - decimal large" {
  let result = tokenize("1234567890") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "1234567890")
}

///| === Alt 1 with -? prefix (negative decimal) ===

test "integer - negative decimal small" {
  let result = tokenize("-1") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "-1")
}

test "integer - negative decimal large" {
  let result = tokenize("-42") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "-42")
}

///| === Alt 2: 0[Xx][0-9A-Fa-f]+ (hex) ===

test "integer - hex lowercase x" {
  let result = tokenize("0x1A") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "0x1A")
}

test "integer - hex uppercase X" {
  let result = tokenize("0XFF") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "0XFF")
}

test "integer - hex single digit" {
  let result = tokenize("0x0") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "0x0")
}

test "integer - hex uppercase X single digit" {
  let result = tokenize("0X0") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "0X0")
}

test "integer - hex all hex digits A-F" {
  let result = tokenize("0xDEADBEEF") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "0xDEADBEEF")
}

test "integer - hex mixed case" {
  let result = tokenize("0xAbCdEf") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "0xAbCdEf")
}

///| === Alt 2 with -? prefix (negative hex) ===

test "integer - negative hex" {
  let result = tokenize("-0x1A") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "-0x1A")
}

///| === Alt 3: 0[0-7]* (octal) ===

test "integer - octal zero" {
  let result = tokenize("0") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "0")
}

test "integer - octal single digit" {
  let result = tokenize("01") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "01")
}

test "integer - octal multi digit" {
  let result = tokenize("0777") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "0777")
}

test "integer - octal leading zeros octal" {
  let result = tokenize("007") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "007")
}

///| === Alt 3 with -? prefix (negative octal) ===

test "integer - negative octal" {
  let result = tokenize("-0777") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "-0777")
}

test "integer - negative zero" {
  let result = tokenize("-0") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Integer)
  assert_eq(s.to_owned(), "-0")
}

///| === Edge cases ===

test "integer - 0x no hex digits falls back to octal 0 + identifier x" {
  let result = tokenize("0x") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Integer)
  assert_eq(s0.to_owned(), "0")
  assert_true(t1 is TokenType::Identifier)
  assert_eq(s1.to_owned(), "x")
}

test "integer - 0X no hex digits falls back to octal 0 + identifier X" {
  let result = tokenize("0X") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Integer)
  assert_eq(s0.to_owned(), "0")
  assert_true(t1 is TokenType::Identifier)
  assert_eq(s1.to_owned(), "X")
}

test "integer - -0x falls back to negative octal 0 + identifier x" {
  let result = tokenize("-0x") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Integer)
  assert_eq(s0.to_owned(), "-0")
  assert_true(t1 is TokenType::Identifier)
  assert_eq(s1.to_owned(), "x")
}

test "integer - 08 splits into octal 0 + decimal 8" {
  let result = tokenize("08") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Integer)
  assert_eq(s0.to_owned(), "0")
  assert_true(t1 is TokenType::Integer)
  assert_eq(s1.to_owned(), "8")
}

test "integer - 09 splits into octal 0 + decimal 9" {
  let result = tokenize("09") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Integer)
  assert_eq(s0.to_owned(), "0")
  assert_true(t1 is TokenType::Integer)
  assert_eq(s1.to_owned(), "9")
}

test "integer - just a minus sign is not an integer" {
  let result = tokenize("-") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Other)
  assert_eq(s.to_owned(), "-")
}

test "integer - in context with other tokens" {
  let result = tokenize("const a = 42;") catch { _ => fail("unexpected") }
  let int_tokens = result.filter(fn(pair) {
    let (t, _) = pair
    t is TokenType::Integer
  })
  assert_eq(int_tokens.length(), 1)
  let (_, s) = int_tokens[0]
  assert_eq(s.to_owned(), "42")
}

test "integer - identifier starting with digits" {
  let result = tokenize("42abc") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Integer)
  assert_eq(s0.to_owned(), "42")
  assert_true(t1 is TokenType::Identifier)
  assert_eq(s1.to_owned(), "abc")
}
