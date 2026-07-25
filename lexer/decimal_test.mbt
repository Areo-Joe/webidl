/// Blackbox tests for DECIMAL tokenization, per WebIDL spec:
///   decimal = /-?(([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([Ee][+\-]?[0-9]+)?|[0-9]+[Ee][+\-]?[0-9]+)/

///|
/// === Alt A1: [0-9]+\.[0-9]* (digits . optional-digits) ===
test "decimal - simple float" {
  let result = tokenize("1.0") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "1.0")
}

///|
test "decimal - pi" {
  let result = tokenize("3.14") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "3.14")
}

///|
test "decimal - leading zero float" {
  let result = tokenize("0.5") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "0.5")
}

///|
test "decimal - trailing dot" {
  let result = tokenize("1.") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "1.")
}

///|
test "decimal - zero dot" {
  let result = tokenize("0.0") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "0.0")
}

///|
/// === Alt A2: [0-9]*\.[0-9]+ (optional-digits . digits) ===
test "decimal - leading dot" {
  let result = tokenize(".5") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), ".5")
}

///|
test "decimal - leading dot zero" {
  let result = tokenize(".0") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), ".0")
}

///|
test "decimal - leading dot many digits" {
  let result = tokenize(".12345") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), ".12345")
}

///|
/// === Alt A1 + exponent: [0-9]+\.[0-9]*[Ee][+-]?[0-9]+ ===
test "decimal - with exponent" {
  let result = tokenize("1.5e10") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "1.5e10")
}

///|
test "decimal - uppercase exponent" {
  let result = tokenize("1.5E10") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "1.5E10")
}

///|
test "decimal - negative exponent" {
  let result = tokenize("1.5e-3") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "1.5e-3")
}

///|
test "decimal - positive exponent" {
  let result = tokenize("1.5e+2") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "1.5e+2")
}

///|
test "decimal - trailing dot with exponent" {
  let result = tokenize("1.e10") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "1.e10")
}

///|
test "decimal - small value with exponent" {
  let result = tokenize("0.5e10") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "0.5e10")
}

///|
/// === Alt A2 + exponent: [0-9]*\.[0-9]+[Ee][+-]?[0-9]+ ===
test "decimal - leading dot with exponent" {
  let result = tokenize(".5e10") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), ".5e10")
}

///|
test "decimal - leading dot negative exponent" {
  let result = tokenize(".5e-3") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), ".5e-3")
}

///|
/// === Alt B: [0-9]+[Ee][+-]?[0-9]+ (digits + exponent, no dot) ===
test "decimal - exponent only" {
  let result = tokenize("1e10") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "1e10")
}

///|
test "decimal - uppercase E exponent only" {
  let result = tokenize("1E10") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "1E10")
}

///|
test "decimal - exponent negative sign" {
  let result = tokenize("1e-3") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "1e-3")
}

///|
test "decimal - exponent positive sign" {
  let result = tokenize("1e+2") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "1e+2")
}

///|
test "decimal - zero exponent" {
  let result = tokenize("0e0") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "0e0")
}

///|
/// === Negative (with -? prefix) ===
test "decimal - negative float" {
  let result = tokenize("-1.5") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "-1.5")
}

///|
test "decimal - negative exponent only" {
  let result = tokenize("-1e10") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "-1e10")
}

///|
test "decimal - negative leading dot" {
  let result = tokenize("-.5") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "-.5")
}

///|
test "decimal - negative exponent with sign" {
  let result = tokenize("-1.5e-3") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "-1.5e-3")
}

///|
/// === Longest-match: DECIMAL wins over INTEGER on floats ===
test "decimal - longest match beats integer" {
  let result = tokenize("1.5") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, _) = result[0]
  assert_true(t is TokenType::Decimal)
}

///|
test "decimal - exponent beats integer" {
  let result = tokenize("1e10") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, _) = result[0]
  assert_true(t is TokenType::Decimal)
}

///|
test "decimal - bare integer is not decimal" {
  let result = tokenize("1") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, _) = result[0]
  assert_true(t is TokenType::Integer)
}

///|
/// === Edge cases ===
test "decimal - dot alone is not a decimal" {
  let result = tokenize(".") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Other)
  assert_eq(s.to_owned(), ".")
}

///|
test "decimal - incomplete exponent falls back to integer + identifier" {
  let result = tokenize("1e") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Integer)
  assert_eq(s0.to_owned(), "1")
  assert_true(t1 is TokenType::Identifier)
  assert_eq(s1.to_owned(), "e")
}

///|
test "decimal - incomplete exponent after dot falls back to decimal + identifier" {
  let result = tokenize("1.0e") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Decimal)
  assert_eq(s0.to_owned(), "1.0")
  assert_true(t1 is TokenType::Identifier)
  assert_eq(s1.to_owned(), "e")
}

///|
test "decimal - incomplete exponent with sign" {
  let result = tokenize("1.0e+") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 3)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  let (t2, s2) = result[2]
  assert_true(t0 is TokenType::Decimal)
  assert_eq(s0.to_owned(), "1.0")
  assert_true(t1 is TokenType::Identifier)
  assert_eq(s1.to_owned(), "e")
  assert_true(t2 is TokenType::Other)
  assert_eq(s2.to_owned(), "+")
}

///|
test "decimal - leading dot then identifier" {
  let result = tokenize(".5abc") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Decimal)
  assert_eq(s0.to_owned(), ".5")
  assert_true(t1 is TokenType::Identifier)
  assert_eq(s1.to_owned(), "abc")
}

///|
test "decimal - dot dot" {
  // "1.0.5" -> Decimal("1.0") + Decimal(".5") since ".5" is a valid leading-dot decimal
  let result = tokenize("1.0.5") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Decimal)
  assert_eq(s0.to_owned(), "1.0")
  assert_true(t1 is TokenType::Decimal)
  assert_eq(s1.to_owned(), ".5")
}

///|
test "decimal - long decimal chain" {
  let result = tokenize("3.1415926535") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 1)
  let (t, s) = result[0]
  assert_true(t is TokenType::Decimal)
  assert_eq(s.to_owned(), "3.1415926535")
}

///|
test "decimal - not consuming identifier after decimal" {
  let result = tokenize("1.5abc") catch { _ => fail("unexpected") }
  assert_eq(result.length(), 2)
  let (t0, s0) = result[0]
  let (t1, s1) = result[1]
  assert_true(t0 is TokenType::Decimal)
  assert_eq(s0.to_owned(), "1.5")
  assert_true(t1 is TokenType::Identifier)
  assert_eq(s1.to_owned(), "abc")
}
