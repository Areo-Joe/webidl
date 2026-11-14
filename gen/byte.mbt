///|
/// The byte type corresponds to 8-bit signed integers.
/// byte constant values in IDL are represented with integer tokens.
fn check_byte_constant_value(value : @parser.ConstValue) -> Unit raise {
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
  let number = @string.parse_int(digits, base~)
  let limit = if negative { 128 } else { 127 }
  assert_true(number <= limit)
}
