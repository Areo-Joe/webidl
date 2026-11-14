///|
/// The float type is a floating point numeric type that corresponds to the set of finite single-precision 32-bit IEEE 754 floating point numbers.
/// float constant values in IDL are represented with decimal tokens.
fn check_float_constant_value(value : @parser.ConstValue) -> Unit raise {
  guard value is FloatLiteral(Decimal(token)) else {
    fail("Expected a decimal token")
  }
  let number = @string.parse_double(token)
  if number.abs() == 340282356779733661637539395458142568448.0 {
    assert_true(float_decimal_below_overflow_threshold(token))
  } else {
    assert_true(Float::from_double(number).is_finite())
  }
}

///|
fn float_decimal_below_overflow_threshold(token : StringView) -> Bool raise {
  let magnitude = token.trim_start(chars="-")
  let (mantissa, exponent) = match magnitude.split_once("e") {
    Some(parts) => parts
    None => magnitude.split_once("E").unwrap_or((magnitude, "0"))
  }
  let integer_length = match mantissa.split_once(".") {
    Some((integer, _)) => integer.length()
    None => mantissa.length()
  }
  let digits = mantissa.replace(old=".", new="")
  let significant = digits.trim_start(chars="0")
  let decimal_position = integer_length -
    (digits.length() - significant.length())
  let position = decimal_position.to_double() + @string.parse_double(exponent)
  if position != 39.0 {
    return position < 39.0
  }
  let threshold : StringView = "340282356779733661637539395458142568448"
  for i in 0..<threshold.length() {
    let digit = if i < significant.length() { significant[i] } else { 48 }
    if digit != threshold[i] {
      return digit < threshold[i]
    }
  }
  false
}
