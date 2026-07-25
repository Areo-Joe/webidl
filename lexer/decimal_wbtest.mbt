/// Whitebox tests for DECIMAL regex, per WebIDL spec:
///   decimal = /-?(([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([Ee][+\-]?[0-9]+)?|[0-9]+[Ee][+\-]?[0-9]+)/

///|
/// === Alt A1: [0-9]+\.[0-9]* (digits . optional-digits) ===
test "decimal - simple float" {
  match DECIMAL.execute("1.0") {
    Some(m) => assert_eq(m.content().to_owned(), "1.0")
    None => fail("expected match")
  }
}

///|
test "decimal - pi" {
  match DECIMAL.execute("3.14") {
    Some(m) => assert_eq(m.content().to_owned(), "3.14")
    None => fail("expected match")
  }
}

///|
test "decimal - leading zero float" {
  match DECIMAL.execute("0.5") {
    Some(m) => assert_eq(m.content().to_owned(), "0.5")
    None => fail("expected match")
  }
}

///|
test "decimal - trailing dot" {
  match DECIMAL.execute("1.") {
    Some(m) => assert_eq(m.content().to_owned(), "1.")
    None => fail("expected match")
  }
}

///|
test "decimal - zero dot" {
  match DECIMAL.execute("0.0") {
    Some(m) => assert_eq(m.content().to_owned(), "0.0")
    None => fail("expected match")
  }
}

///|
test "decimal - trailing dot zero" {
  match DECIMAL.execute("0.") {
    Some(m) => assert_eq(m.content().to_owned(), "0.")
    None => fail("expected match")
  }
}

///|
/// === Alt A2: [0-9]*\.[0-9]+ (optional-digits . digits) ===
test "decimal - leading dot" {
  match DECIMAL.execute(".5") {
    Some(m) => assert_eq(m.content().to_owned(), ".5")
    None => fail("expected match")
  }
}

///|
test "decimal - leading dot zero" {
  match DECIMAL.execute(".0") {
    Some(m) => assert_eq(m.content().to_owned(), ".0")
    None => fail("expected match")
  }
}

///|
test "decimal - leading dot many digits" {
  match DECIMAL.execute(".12345") {
    Some(m) => assert_eq(m.content().to_owned(), ".12345")
    None => fail("expected match")
  }
}

///|
/// === Alt A1 + exponent: [0-9]+\.[0-9]*[Ee][+-]?[0-9]+ ===
test "decimal - with exponent" {
  match DECIMAL.execute("1.5e10") {
    Some(m) => assert_eq(m.content().to_owned(), "1.5e10")
    None => fail("expected match")
  }
}

///|
test "decimal - uppercase exponent" {
  match DECIMAL.execute("1.5E10") {
    Some(m) => assert_eq(m.content().to_owned(), "1.5E10")
    None => fail("expected match")
  }
}

///|
test "decimal - exponent negative sign" {
  match DECIMAL.execute("1.5e-3") {
    Some(m) => assert_eq(m.content().to_owned(), "1.5e-3")
    None => fail("expected match")
  }
}

///|
test "decimal - exponent positive sign" {
  match DECIMAL.execute("1.5e+2") {
    Some(m) => assert_eq(m.content().to_owned(), "1.5e+2")
    None => fail("expected match")
  }
}

///|
test "decimal - trailing dot with exponent" {
  match DECIMAL.execute("1.e10") {
    Some(m) => assert_eq(m.content().to_owned(), "1.e10")
    None => fail("expected match")
  }
}

///|
test "decimal - small value with exponent" {
  match DECIMAL.execute("0.5e10") {
    Some(m) => assert_eq(m.content().to_owned(), "0.5e10")
    None => fail("expected match")
  }
}

///|
/// === Alt A2 + exponent: [0-9]*\.[0-9]+[Ee][+-]?[0-9]+ ===
test "decimal - leading dot with exponent" {
  match DECIMAL.execute(".5e10") {
    Some(m) => assert_eq(m.content().to_owned(), ".5e10")
    None => fail("expected match")
  }
}

///|
test "decimal - leading dot negative exponent" {
  match DECIMAL.execute(".5e-3") {
    Some(m) => assert_eq(m.content().to_owned(), ".5e-3")
    None => fail("expected match")
  }
}

///|
/// === Alt B: [0-9]+[Ee][+-]?[0-9]+ (digits + exponent, no dot) ===
test "decimal - exponent only" {
  match DECIMAL.execute("1e10") {
    Some(m) => assert_eq(m.content().to_owned(), "1e10")
    None => fail("expected match")
  }
}

///|
test "decimal - uppercase E exponent only" {
  match DECIMAL.execute("1E10") {
    Some(m) => assert_eq(m.content().to_owned(), "1E10")
    None => fail("expected match")
  }
}

///|
test "decimal - exponent only negative sign" {
  match DECIMAL.execute("1e-3") {
    Some(m) => assert_eq(m.content().to_owned(), "1e-3")
    None => fail("expected match")
  }
}

///|
test "decimal - exponent only positive sign" {
  match DECIMAL.execute("1e+2") {
    Some(m) => assert_eq(m.content().to_owned(), "1e+2")
    None => fail("expected match")
  }
}

///|
test "decimal - zero exponent" {
  match DECIMAL.execute("0e0") {
    Some(m) => assert_eq(m.content().to_owned(), "0e0")
    None => fail("expected match")
  }
}

///|
/// === Negative (with -? prefix) ===
test "decimal - negative float" {
  match DECIMAL.execute("-1.5") {
    Some(m) => assert_eq(m.content().to_owned(), "-1.5")
    None => fail("expected match")
  }
}

///|
test "decimal - negative exponent only" {
  match DECIMAL.execute("-1e10") {
    Some(m) => assert_eq(m.content().to_owned(), "-1e10")
    None => fail("expected match")
  }
}

///|
test "decimal - negative leading dot" {
  match DECIMAL.execute("-.5") {
    Some(m) => assert_eq(m.content().to_owned(), "-.5")
    None => fail("expected match")
  }
}

///|
test "decimal - negative exponent with sign" {
  match DECIMAL.execute("-1.5e-3") {
    Some(m) => assert_eq(m.content().to_owned(), "-1.5e-3")
    None => fail("expected match")
  }
}

///|
/// === Should NOT match ===
test "decimal - no match on plain integer" {
  match DECIMAL.execute("1") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "decimal - no match on letters" {
  match DECIMAL.execute("abc") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "decimal - no match on empty string" {
  match DECIMAL.execute("") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "decimal - no match on dot alone" {
  match DECIMAL.execute(".") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
/// === Partial matches ===
test "decimal - partial 1.0e leaves 1.0" {
  match DECIMAL.execute("1.0e") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "1.0")
      assert_eq(m.after().to_owned(), "e")
    }
    None => fail("expected match")
  }
}

///|
test "decimal - partial 1e leaves 1" {
  match DECIMAL.execute("1e") {
    Some(_) => fail("expected no match")
    None => ()
  }
}

///|
test "decimal - partial 1.0e+ leaves 1.0" {
  match DECIMAL.execute("1.0e+") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "1.0")
      assert_eq(m.after().to_owned(), "e+")
    }
    None => fail("expected match")
  }
}

///|
test "decimal - partial .5abc leaves abc" {
  match DECIMAL.execute(".5abc") {
    Some(m) => {
      assert_eq(m.content().to_owned(), ".5")
      assert_eq(m.after().to_owned(), "abc")
    }
    None => fail("expected match")
  }
}

///|
test "decimal - long decimal chain" {
  match DECIMAL.execute("3.1415926535") {
    Some(m) => assert_eq(m.content().to_owned(), "3.1415926535")
    None => fail("expected match")
  }
}

///|
test "decimal - partial 1.5abc leaves abc" {
  match DECIMAL.execute("1.5abc") {
    Some(m) => {
      assert_eq(m.content().to_owned(), "1.5")
      assert_eq(m.after().to_owned(), "abc")
    }
    None => fail("expected match")
  }
}
