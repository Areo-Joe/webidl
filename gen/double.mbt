///|
/// The double type is a floating point numeric type that corresponds to the set of finite double-precision 64-bit IEEE 754 floating point numbers.
/// double constant values in IDL are represented with decimal tokens.
fn check_double_constant_value(value : @parser.ConstValue) -> Unit raise {
  guard value is FloatLiteral(Decimal(token)) else {
    fail("Expected a decimal token")
  }
  let number = @string.parse_double(token)
  assert_true(number.is_finite())
}
