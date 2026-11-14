///|
fn integer_constant_value(value : @parser.ConstValue) -> Int64 raise {
  guard value is Integer(token) else { fail("Expected an integer token") }
  let negative = token.has_prefix("-")
  let digits = if negative { token[1:] } else { token }
  let (base, digits) = if digits.has_prefix("0x") || digits.has_prefix("0X") {
    (16, digits[2:])
  } else if digits.has_prefix("0") {
    (8, digits)
  } else {
    (10, digits)
  }
  let number = if negative {
    "-" + digits.to_owned()
  } else {
    digits.to_owned()
  }
  @string.parse_int64(number, base~)
}
