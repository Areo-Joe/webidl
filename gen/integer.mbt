///|
fn integer_constant_parts(
  value : @parser.ConstValue,
) -> (Bool, Int32, StringView) raise {
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
  (negative, base, digits)
}

///|
fn integer_constant_value(value : @parser.ConstValue) -> Int64 raise {
  let (negative, base, digits) = integer_constant_parts(value)
  let number = if negative {
    "-" + digits.to_owned()
  } else {
    digits.to_owned()
  }
  @string.parse_int64(number, base~)
}

///|
fn unsigned_integer_constant_value(value : @parser.ConstValue) -> UInt64 raise {
  let (negative, base, digits) = integer_constant_parts(value)
  let number = @string.parse_uint64(digits, base~)
  assert_true(!negative || number == 0)
  number
}
