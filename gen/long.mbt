///|
/// The long type corresponds to 32-bit signed integers.
/// long constant values in IDL are represented with integer tokens.
fn check_long_constant_value(value : @parser.ConstValue) -> Unit raise {
  let number = integer_constant_value(value)
  assert_true(number >= -2147483648L && number <= 2147483647L)
}
